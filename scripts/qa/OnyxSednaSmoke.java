import java.io.*;
import java.nio.*;
import java.nio.file.*;
import java.util.*;
import java.util.regex.Pattern;
import li.cil.sedna.Sedna;
import li.cil.sedna.api.device.*;
import li.cil.sedna.api.devicetree.*;
import li.cil.sedna.api.memory.MemoryMap;
import li.cil.sedna.device.block.ByteBufferBlockDevice;
import li.cil.sedna.device.memory.Memory;
import li.cil.sedna.device.serial.UART16550A;
import li.cil.sedna.device.virtio.*;
import li.cil.sedna.devicetree.DeviceTreeRegistry;
import li.cil.sedna.memory.MemoryMaps;
import li.cil.sedna.riscv.R5Board;

/** Real RV64 guest execution, UART login/shell/filesystem and three independent MMIO displays. */
public final class OnyxSednaSmoke {
    final R5Board board = new R5Board();
    final UART16550A uart = new UART16550A();
    final VirtIOKeyboardDevice keyboard = new VirtIOKeyboardDevice(board.getMemoryMap());
    final StringBuilder output = new StringBuilder();
    final Display first = new Display(640,400), second = new Display(640,400), third = new Display(640,480);
    final ByteBufferBlockDevice disk;
    final VirtIOKeyboardDevice secondKeyboard;
    int scan;
    boolean interactive;
    OnyxSednaSmoke(String[] args)throws Exception {
        Sedna.initialize();
        DeviceTreeRegistry.putProvider(UART16550A.class,new Provider("uart","ns16550a"));
        DeviceTreeRegistry.putProvider(AbstractVirtIODevice.class,new Provider("virtio","virtio,mmio"));
        DeviceTreeRegistry.putProvider(Display.class,new Provider("framebuffer","simple-framebuffer"));
        int ram = args.length>3?Integer.parseInt(args[3]):64;
        board.addDevice(0x80000000L,Memory.create(ram*1024*1024));
        board.addDevice(0x10000000L,uart);uart.getInterrupt().set(4,board.getInterruptController());board.setStandardOutputDevice(uart);
        disk=ByteBufferBlockDevice.wrap(ByteBuffer.wrap(Files.readAllBytes(Path.of(args[2]))),false);
        VirtIOBlockDevice block = new VirtIOBlockDevice(board.getMemoryMap(),disk);
        board.addDevice(0x10001000L,block);block.getInterrupt().set(7,board.getInterruptController());
        board.addDevice(0x3020d400L,keyboard);keyboard.getInterrupt().set(8,board.getInterruptController());
        secondKeyboard = new VirtIOKeyboardDevice(board.getMemoryMap());
        board.addDevice(0x3028a600L,secondKeyboard);secondKeyboard.getInterrupt().set(9,board.getInterruptController());
        // Deliberately packed and reordered: fb0 begins after a sub-page gap.
        board.addDevice(0x30190400L,first);board.addDevice(0x3020d600L,second);board.addDevice(0x3028a800L,third);
        MemoryMaps.store(board.getMemoryMap(),0x80000000L,Files.newInputStream(Path.of(args[0])));
        MemoryMaps.store(board.getMemoryMap(),0x80200000L,Files.newInputStream(Path.of(args[1])));
        board.initialize();board.setRunning(true);
    }
    void step() {
        board.step(20000);
        int c;while((c=uart.read())>=0){System.out.write(c);output.append((char)c);}System.out.flush();
        String tail=output.substring(Math.max(0,output.length()-500));
        if(tail.contains("KERNEL page fault")||tail.contains("PANIC"))throw new AssertionError("guest fault");
    }
    void waitFor(String needle)throws Exception {
        long until=System.nanoTime()+120_000_000_000L;
        while(System.nanoTime()<until){step();if(output.indexOf(needle,scan)>=0){scan=output.length();return;}}
        throw new AssertionError("timeout waiting for "+needle);
    }
    void line(String value)throws Exception {
        scan=output.length();
        byte[] bytes=(value+"\r").getBytes(java.nio.charset.StandardCharsets.UTF_8);
        for(byte b:bytes){while(!uart.canPutByte())step();uart.putByte(b);step();}
        if(interactive) {
            long until=System.nanoTime()+120_000_000_000L;
            while(output.indexOf("osh$ ",scan)<0) { if(System.nanoTime()>until)throw new AssertionError("shell command timeout: "+value);step(); }
        }
    }
    void marker(String value)throws Exception {
        long until=System.nanoTime()+120_000_000_000L;
        Pattern exact=Pattern.compile("(?m)^"+Pattern.quote(value)+"\\r?$");
        while(System.nanoTime()<until){step();if(exact.matcher(output.substring(scan)).find()){scan=output.length();return;}}
        throw new AssertionError("timeout waiting for output line "+value);
    }
    public static void main(String[] args)throws Exception {
        if(args.length<3)throw new IllegalArgumentException("OpenSBI kernel.bin rootfs.img [RAM_MiB] [saved-rootfs.img] [reload]");
        var t=new OnyxSednaSmoke(args);
        t.waitFor("login: ");t.line("root");t.waitFor("password: ");t.line("");t.waitFor("Login OK (root, ring 1)");
        if (args.length <= 5 && !t.output.toString().contains("-> " + (t.disk.getCapacity()/4096) + " blocks"))
            throw new AssertionError("rootfs did not grow to actual backing capacity");
        t.waitFor("OnyxShell");t.waitFor("osh$ ");t.interactive=true;
        t.line("echo ONYX_SHELL_OK");t.marker("ONYX_SHELL_OK");
        // Start an actual command through virtio-input, finish through UART.
        System.err.println("KEYBOARD status before="+t.keyboard.load(0x70,2));
        t.scan=t.output.length();t.keyboard.sendKeyEvent(18,true);t.keyboard.sendKeyEvent(18,false);
        for(int i=0;i<1000;i++)t.step();
        System.err.println("KEYBOARD status after="+t.keyboard.load(0x70,2));
        t.waitFor("e");t.line("cho ONYX_KEYBOARD_OK");t.marker("ONYX_KEYBOARD_OK");
        if(args.length>5&&args[5].equals("reload")) {
            t.line("cat /tmp/onyx-qa/marker");t.marker("OC2R_ONYX_PERSIST");
        } else {
            t.line("mkdir /tmp/onyx-qa");
            t.line("echo OC2R_ONYX_PERSIST > /tmp/onyx-qa/marker");
            t.line("cat /tmp/onyx-qa/marker");t.marker("OC2R_ONYX_PERSIST");
            t.line("cp /tmp/onyx-qa/marker /tmp/onyx-qa/copy");
            t.line("mv /tmp/onyx-qa/copy /tmp/onyx-qa/renamed");
            t.line("cat /tmp/onyx-qa/renamed");t.marker("OC2R_ONYX_PERSIST");
            t.line("rm /tmp/onyx-qa/renamed");
        }
        t.line("pwd > /tmp/onyx-qa/pwd");
        t.line("cat /tmp/onyx-qa/pwd");t.marker("/");
        t.line("ls /dev");t.waitFor("fb2");
        t.draw(2,"blue",31);t.draw(1,"green",2016);t.draw(0,"red",63488);
        if(t.keyboard.load(0,2)!=0x74726976L || t.secondKeyboard.load(0,2)!=0x74726976L
            || t.keyboard.load(0x70,2)!=15 || t.secondKeyboard.load(0x70,2)!=0)
            throw new AssertionError("framebuffer writes corrupted adjacent keyboard MMIO");
        if(args.length>4)try(var input=t.disk.getInputStream(0)){Files.copy(input,Path.of(args[4]),StandardCopyOption.REPLACE_EXISTING);}
        System.err.println("ONYX_SEDNA_SMOKE_PASS RAM="+(args.length>3?args[3]:"64")+" framebufferWrites="+t.first.writes+","+t.second.writes+","+t.third.writes);
    }
    Display display(int index) {
        var matcher=Pattern.compile("simple-framebuffer at 0x([0-9a-fA-F]+)").matcher(output);
        for(int i=0;matcher.find();i++)if(i==index) {
            long address=Long.parseUnsignedLong(matcher.group(1),16);
            if(address==0x30190400L)return first;
            if(address==0x3020d600L)return second;
            if(address==0x3028a800L)return third;
        }
        throw new AssertionError("missing framebuffer index "+index);
    }
    void draw(int index,String color,int rgb)throws Exception {
        var d=display(index);d.expected=rgb;d.firstSeen=false;d.lastSeen=false;
        line("run /bin/fb-draw /dev/fb"+index+" "+color);
        marker("FB_DRAW_OK "+d.width+"x"+d.height+"x16");
        if(!d.firstSeen||!d.lastSeen)throw new AssertionError("incorrect physical first/last pixel fb"+index);
        // fb0's console can overwrite its pixels after the diagnostic exits.
        if(index!=0 && ((d.pixels.getShort(0)&65535)!=rgb || (d.pixels.getShort(d.getLength()-2)&65535)!=rgb))
            throw new AssertionError("surface corner colors differ fb"+index);
    }
    static final class Display implements MemoryMappedDevice {
        final int width,height;final ByteBuffer pixels;long writes,redWrites;int expected=-1;boolean firstSeen,lastSeen;
        Display(int w,int h){width=w;height=h;pixels=ByteBuffer.allocate(w*h*2).order(ByteOrder.LITTLE_ENDIAN);}
        public int getLength(){return pixels.capacity();}public int getSupportedSizes(){return 15;}
        public long load(int o,int s){return switch(s){case 0->pixels.get(o)&255L;case 1->pixels.getShort(o)&65535L;case 2->Integer.toUnsignedLong(pixels.getInt(o));default->pixels.getLong(o);};}
        public void store(int o,long v,int s){writes++;if((v&65535)==63488)redWrites++;
            if(s==1 && (v&65535)==expected) {if(o==0)firstSeen=true;if(o==getLength()-2)lastSeen=true;}
            switch(s){case 0->pixels.put(o,(byte)v);case 1->pixels.putShort(o,(short)v);case 2->pixels.putInt(o,(int)v);default->pixels.putLong(o,v);}}
        int nonzero(){int n=0;for(int i=0;i<pixels.capacity();i++)if(pixels.get(i)!=0)n++;return n;}
    }
    static final class Provider implements DeviceTreeProvider {
        final String name,compatible;Provider(String n,String c){name=n;compatible=c;}
        public Optional<String> getName(Device d){return Optional.of(name);}
        public Optional<DeviceTree> createNode(DeviceTree r,MemoryMap m,Device d,String n){return m.getMemoryRange((MemoryMappedDevice)d).map(range->r.find("/soc").getChild(name,range.address()));}
        public void visit(DeviceTree node,MemoryMap map,Device d){node.addProp("compatible",compatible);
            if(d instanceof UART16550A)node.addProp("clock-frequency",3686400);
            if(d instanceof Display f)node.addProp("width",f.width).addProp("height",f.height).addProp("stride",f.width*2).addProp("format","r5g6b5").addProp("status","okay");}
    }
}

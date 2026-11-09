import java.nio.*;
import java.nio.file.*;
import java.util.*;
import li.cil.sedna.Sedna;
import li.cil.sedna.api.memory.MemoryMap;
import li.cil.sedna.device.block.ByteBufferBlockDevice;
import li.cil.sedna.device.memory.Memory;
import li.cil.sedna.device.serial.UART16550A;
import li.cil.sedna.device.virtio.*;
import li.cil.sedna.devicetree.DeviceTreeRegistry;
import li.cil.sedna.memory.MemoryMaps;
import li.cil.sedna.riscv.R5Board;

/** Execute real local widgets with the tablet's exact display/input and 16 MiB RAM. */
public final class OnyxTabletSmoke {
    final R5Board board = new R5Board();
    final UART16550A uart = new UART16550A();
    final OnyxSednaSmoke.Display display = new OnyxSednaSmoke.Display(256, 160);
    final Pointer input = new Pointer(board.getMemoryMap());
    final StringBuilder output = new StringBuilder();
    int scan;
    OnyxTabletSmoke(String[] args) throws Exception {
        Sedna.initialize();
        DeviceTreeRegistry.putProvider(UART16550A.class, new OnyxSednaSmoke.Provider("uart", "ns16550a"));
        DeviceTreeRegistry.putProvider(AbstractVirtIODevice.class, new OnyxSednaSmoke.Provider("virtio", "virtio,mmio"));
        DeviceTreeRegistry.putProvider(OnyxSednaSmoke.Display.class, new OnyxSednaSmoke.Provider("framebuffer", "simple-framebuffer"));
        board.addDevice(0x80000000L, Memory.create(16 * 1024 * 1024));
        board.addDevice(0x10000000L, uart);
        uart.getInterrupt().set(4, board.getInterruptController());
        board.setStandardOutputDevice(uart);
        var disk = ByteBufferBlockDevice.wrap(ByteBuffer.wrap(Files.readAllBytes(Path.of(args[2]))), false);
        var block = new VirtIOBlockDevice(board.getMemoryMap(), disk);
        board.addDevice(0x10001000L, block); block.getInterrupt().set(7, board.getInterruptController());
        board.addDevice(0x10002000L, input); input.getInterrupt().set(8, board.getInterruptController());
        board.addDevice(0x30000000L, display);
        MemoryMaps.store(board.getMemoryMap(), 0x80000000L, Files.newInputStream(Path.of(args[0])));
        MemoryMaps.store(board.getMemoryMap(), 0x80200000L, Files.newInputStream(Path.of(args[1])));
        board.initialize(); board.setRunning(true);
    }
    void step() {
        board.step(20000);
        int c; while ((c = uart.read()) >= 0) { System.out.write(c); output.append((char)c); }
        System.out.flush();
        String tail = output.substring(Math.max(0, output.length()-500));
        if (tail.contains("KERNEL page fault") || tail.contains("PANIC")) throw new AssertionError("guest fault");
    }
    void waitFor(String text) {
        long until = System.nanoTime() + 120_000_000_000L;
        while (System.nanoTime() < until) { step(); if (output.indexOf(text, scan) >= 0) { scan = output.length(); return; } }
        throw new AssertionError("timeout: " + text);
    }
    void line(String text) {
        scan = output.length();
        for (byte b : (text + "\r").getBytes(java.nio.charset.StandardCharsets.UTF_8)) {
            while (!uart.canPutByte()) step(); uart.putByte(b); step();
        }
    }
    void painted(int x, int y, int color) {
        long until = System.nanoTime() + 20_000_000_000L;
        while (System.nanoTime() < until) {
            step(); if ((display.pixels.getShort((y*256+x)*2)&65535) == color) return;
        }
        throw new AssertionError("missing guest pixels at "+x+","+y+" got="+Integer.toHexString(display.pixels.getShort((y*256+x)*2)&65535)+" writes="+display.writes);
    }
    byte[] header() {
        byte[] result = new byte[224*12*2]; int i = 0;
        for (int y=32; y<44; y++) for (int x=16; x<240; x++) {
            result[i++] = display.pixels.get((y*256+x)*2);
            result[i++] = display.pixels.get((y*256+x)*2+1);
        }
        return result;
    }
    public static void main(String[] args) throws Exception {
        if (args.length < 3 || args.length > 4) throw new IllegalArgumentException("fw_jump.bin kernel.bin rootfs.img [kill-test]");
        var t = new OnyxTabletSmoke(args);
        t.waitFor("login: "); t.line("root");
        t.waitFor("Login OK (root, ring 1)"); t.waitFor("osh$ ");
        t.line("otablet --device"); t.waitFor("OTABLET_READY 256x160");
        // A 40 ms guest-time click overlaps the expensive initial redraw.
        t.input.pointer(30,98,true); for(int i=0;i<100;i++)t.step();
        t.input.pointer(30,98,false);
        t.painted(18,102,0x2457);
        byte[] header = t.header();
        t.waitFor("OTABLET_CLICK=1");
        t.painted(16,70,0x07E0);
        for(int i=0;i<400;i++) { t.step(); if(!Arrays.equals(header,t.header()))throw new AssertionError("console overwrote widgets"); }
        int before=t.output.length();
        t.input.pointer(30,98,true); for(int i=0;i<5000;i++)t.step();
        t.input.pointer(0,0,false); for(int i=0;i<5000;i++)t.step();
        if(t.output.indexOf("OTABLET_CLICK=2",before)>=0)throw new AssertionError("release outside fired action");
        t.scan=t.output.length(); t.input.key(16,true); t.input.key(16,false); t.waitFor("OTABLET_EXIT");
        t.waitFor("osh$ "); t.line("echo TABLET_SHELL_OK"); t.waitFor("\nTABLET_SHELL_OK"); t.waitFor("osh$ ");
        if (args.length == 4) {
            t.line("tablet-kill"); t.waitFor("OTABLET_READY 256x160");
            t.waitFor("OTABLET_KILL_RECLAIM_OK"); t.waitFor("osh$ ");
        }
        System.err.println("ONYX_TABLET_SMOKE_PASS RAM=16 display=256x160 pointer=absolute counter=1 short-click=40ms exit=q");
    }
    static final class Pointer extends AbstractVirtIOInputDevice {
        Pointer(MemoryMap map) { super(map); }
        void pointer(int x,int y,boolean down) { putEvents(packEvent(3,0,x),packEvent(3,1,y),packEvent(1,0x110,down?1:0),packEvent(0,0,0)); }
        void key(int key,boolean down) { putEvents(packEvent(1,key,down?1:0),packEvent(0,0,0)); }
        protected int generateConfigUnion(int select,int sub,ByteBuffer out) {
            if(select==VIRTIO_INPUT_CFG_SELECT_ID_NAME){byte[] name="Onyx tablet smoke".getBytes(java.nio.charset.StandardCharsets.US_ASCII);out.put(name);return name.length;}
            if(select==VIRTIO_INPUT_CFG_SELECT_EV_BITS){
                if(sub==1){for(int i=0;i<35;i++)out.put((byte)255);return 35;}
                if(sub==3){out.put((byte)3);return 1;}
            }
            if(select==VIRTIO_INPUT_CFG_SELECT_ABS_INFO&&(sub==0||sub==1)){out.putInt(0).putInt(sub==0?255:159).putInt(0).putInt(0).putInt(0);return 20;}
            return 0;
        }
    }
}

import android.os.SystemClock;
import android.view.InputDevice;
import android.view.InputEvent;
import android.view.MotionEvent;
import java.lang.reflect.Method;

// Test-only shell runner: one pointer, one downTime, including the return/cancel path.
public final class BackGesture {
    private static Object input;
    private static Method inject;
    private static long downTime;

    private static void send(int action, float x, float y) throws Exception {
        MotionEvent.PointerProperties pointer = new MotionEvent.PointerProperties();
        pointer.id = 0;
        pointer.toolType = MotionEvent.TOOL_TYPE_FINGER;
        MotionEvent.PointerCoords point = new MotionEvent.PointerCoords();
        point.x = x;
        point.y = y;
        point.pressure = action == MotionEvent.ACTION_UP ? 0 : 1;
        point.size = 1;
        MotionEvent event = MotionEvent.obtain(downTime, SystemClock.uptimeMillis(), action,
                1, new MotionEvent.PointerProperties[] { pointer },
                new MotionEvent.PointerCoords[] { point }, 0, 0, 1, 1, 0, 0,
                InputDevice.SOURCE_TOUCHSCREEN, 0);
        try {
            if (!((Boolean) inject.invoke(input, event, 2))) {
                throw new IllegalStateException("Touch injection failed");
            }
        } finally {
            event.recycle();
        }
    }

    private static void move(float fromX, float fromY, float toX, float toY) throws Exception {
        for (int step = 1; step <= 10; ++step) {
            SystemClock.sleep(15);
            send(MotionEvent.ACTION_MOVE, fromX + (toX - fromX) * step / 10,
                    fromY + (toY - fromY) * step / 10);
        }
    }

    public static void main(String[] args) throws Exception {
        Class<?> manager = Class.forName("android.hardware.input.InputManagerGlobal");
        input = manager.getMethod("getInstance").invoke(null);
        inject = manager.getMethod("injectInputEvent", InputEvent.class, int.class);
        if (args[0].equals("double-tap")) {
            float x = Float.parseFloat(args[1]);
            float y = Float.parseFloat(args[2]);
            for (int tap = 0; tap < 2; ++tap) {
                downTime = SystemClock.uptimeMillis();
                send(MotionEvent.ACTION_DOWN, x, y);
                SystemClock.sleep(40);
                send(MotionEvent.ACTION_UP, x, y);
                SystemClock.sleep(60);
            }
            return;
        }
        float start = Float.parseFloat(args[0]);
        float outward = Float.parseFloat(args[1]);
        float y = Float.parseFloat(args[2]);
        float endY = args.length > 5 ? Float.parseFloat(args[5]) : y;
        boolean cancel = Boolean.parseBoolean(args[3]);
        downTime = SystemClock.uptimeMillis();
        send(MotionEvent.ACTION_DOWN, start, y);
        SystemClock.sleep(Long.parseLong(args[4]));
        move(start, y, outward, endY);
        SystemClock.sleep(args.length > 6 ? Long.parseLong(args[6]) : 1000);
        if (cancel) {
            move(outward, endY, start, y);
        }
        send(MotionEvent.ACTION_UP, cancel ? start : outward, cancel ? y : endY);
    }
}

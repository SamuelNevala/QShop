import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.drawable.AdaptiveIconDrawable;
import android.graphics.drawable.Drawable;
import android.os.Looper;
import java.io.File;
import java.io.FileOutputStream;

/** Draw the installed package's actual resources with Android's native renderer. */
public class IconProbe {
    private static void save(Drawable drawable, File destination) throws Exception {
        Bitmap image = Bitmap.createBitmap(512, 512, Bitmap.Config.ARGB_8888);
        drawable.setBounds(0, 0, 512, 512);
        drawable.draw(new Canvas(image));
        try (FileOutputStream stream = new FileOutputStream(destination)) {
            image.compress(Bitmap.CompressFormat.PNG, 100, stream);
        }
    }

    public static void main(String[] args) throws Exception {
        Looper.prepareMainLooper();
        Class<?> activityThread = Class.forName("android.app.ActivityThread");
        Object thread = activityThread.getMethod("systemMain").invoke(null);
        Context context = (Context) activityThread.getMethod("getSystemContext").invoke(thread);
        PackageManager manager = context.getPackageManager();
        PackageInfo info = manager.getPackageInfo("shopper.nevala.com", 0);
        Drawable icon = manager.getApplicationIcon("shopper.nevala.com");
        if (!(icon instanceof AdaptiveIconDrawable)) {
            throw new AssertionError("Installed icon is not adaptive: " + icon.getClass());
        }
        AdaptiveIconDrawable adaptive = (AdaptiveIconDrawable) icon;
        File output = new File(args[0]);
        save(adaptive, new File(output, "adaptive.png"));
        save(adaptive.getForeground(), new File(output, "foreground.png"));
        save(adaptive.getBackground(), new File(output, "background.png"));
        if (adaptive.getMonochrome() == null) {
            throw new AssertionError("Themed icon layer missing");
        }
        save(adaptive.getMonochrome(), new File(output, "monochrome.png"));
        System.out.println("VERSION " + info.versionName + " " + info.getLongVersionCode());
        System.out.println("PASS native adaptive/foreground/background/monochrome resources");
    }
}

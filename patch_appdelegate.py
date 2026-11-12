"""AppDelegate.swift-ə Firebase başlanğıcını və APNs token ötürülməsini əlavə edir (təkrar işə salmaq təhlükəsizdir)."""
import re
import sys

path = sys.argv[1]
s = open(path, encoding="utf-8").read()

if "import FirebaseCore" not in s:
    s = s.replace("import Capacitor", "import Capacitor\nimport FirebaseCore", 1)

if "FirebaseApp.configure()" not in s:
    s, n = re.subn(
        r"(didFinishLaunchingWithOptions[^{]*\{)",
        r"\1\n        FirebaseApp.configure()",
        s,
        count=1,
    )
    if n != 1:
        sys.exit("didFinishLaunchingWithOptions tapılmadı")

if "didRegisterForRemoteNotificationsWithDeviceToken" not in s:
    extra = """
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationCenter.default.post(name: .capacitorDidRegisterForRemoteNotifications, object: deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NotificationCenter.default.post(name: .capacitorDidFailToRegisterForRemoteNotifications, object: error)
    }
}
"""
    idx = s.rstrip().rfind("}")
    s = s[:idx].rstrip() + "\n" + extra

open(path, "w", encoding="utf-8").write(s)
print("AppDelegate yeniləndi")

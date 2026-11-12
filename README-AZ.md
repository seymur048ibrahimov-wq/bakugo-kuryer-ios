# BakuGo Kuryer — iOS (App Store) layihəsi

Bu qovluq PWA kuryer tətbiqini **Capacitor** ilə native iOS tətbiqinə çevirir.
Mac-ınız yoxdursa, yığım **Codemagic**-də (bulud Mac) aparılır və birbaşa TestFlight-a yüklənir.

```
bakugo-kuryer-ios/
├─ www/                  ← veb tətbiq (index.html iOS üçün yamaqlanıb)
├─ resources/            ← 1024×1024 ikon + splash (ikonlar avtomatik yaradılır)
├─ scripts/              ← Info.plist, push, Firebase, Xcode tənzimləmələri
├─ capacitor.config.json ← appId: az.bakugo.kuryer
├─ codemagic.yaml        ← bulud yığımı + TestFlight
└─ package.json
```

## index.html-də nə dəyişdi
- **Push bildirişləri**: iPhone-da tətbiq daxilində web-push işləmir. Tətbiq indi native
  FCM tokenini (`@capacitor-firebase/messaging`) alır və eyni yerə yazır:
  `couriers/{uid}.fcmToken` (+ `fcmPlatform: "ios"`). Server tərəfi dəyişmədən eyni tokenə göndərə bilir.
- **Notch / Dynamic Island**: `.app`-a safe-area boşluğu əlavə olundu (yalnız iOS tətbiqində).
- Brauzer/Android versiyasında heç nə dəyişmir.

---

## 1. Apple Developer (bir dəfəlik)
1. https://developer.apple.com — **Apple Developer Program** (99 $/il). Şirkət adına açmaq üçün
   D-U-N-S nömrəsi lazımdır; fərdi hesabla da açmaq olar.
2. **Certificates, IDs & Profiles → Identifiers → +** → App ID:
   - Bundle ID: `az.bakugo.kuryer`
   - Capabilities: **Push Notifications** ✅
3. **Keys → +** → *Apple Push Notifications service (APNs)* → `.p8` faylını yükləyin
   (Key ID və Team ID-ni qeyd edin).

## 2. App Store Connect
1. https://appstoreconnect.apple.com → **Apps → + New App**
   - Platform: iOS, Name: *BakuGo Kuryer*, Bundle ID: `az.bakugo.kuryer`, SKU: `bakugo-kuryer`
2. **App Information**-dakı rəqəmli **Apple ID**-ni `codemagic.yaml` → `APP_STORE_APPLE_ID`-ə yazın.
3. **Users and Access → Integrations → App Store Connect API → +** (rol: *App Manager*)
   → `.p8` açarını, Issuer ID və Key ID-ni götürün.

## 3. Firebase
1. Firebase Console → layihə → **Add app → iOS** → Bundle ID `az.bakugo.kuryer`.
2. **GoogleService-Info.plist** yükləyin.
3. **Project settings → Cloud Messaging → Apple app configuration** → APNs `.p8` açarını
   (Key ID + Team ID) yükləyin. ⚠️ Bu olmasa iPhone-a push gəlməz.
4. **Authentication → Settings → Authorized domains**-də `localhost` olsun (default var).

## 4. Google Maps açarı
iOS tətbiqi səhifəni `capacitor://localhost` ünvanından açır. Google Cloud Console-da Maps
açarı **HTTP referrer** ilə məhdudlaşdırılıbsa, xəritə açılmaya bilər — `capacitor://localhost/*`
əlavə edin, alınmasa iOS üçün ayrıca açar yaradın.

## 5. Codemagic ilə yığım (Mac lazım deyil)
1. Bu qovluğu GitHub-da yeni repoya yükləyin (məs. `bakugo-kuryer-ios`).
2. https://codemagic.io → GitHub ilə daxil olun → **Add application** → repo seçin → *codemagic.yaml*.
3. **Team settings → Integrations → App Store Connect** → 2.3-dəki API açarını əlavə edin,
   adını **`BakuGo ASC`** qoyun.
4. **Team settings → Code signing identities**:
   - *iOS certificates* → **Generate certificate** (Apple Distribution)
   - *iOS provisioning profiles* → **Fetch profiles** → `az.bakugo.kuryer` (App Store)
5. **App → Environment variables** → qrup **`firebase_ios`**, dəyişən **`GOOGLE_SERVICE_INFO_PLIST`**:
   ```bash
   # Mac/Linux:  base64 -i GoogleService-Info.plist | pbcopy
   # Windows PowerShell:
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("GoogleService-Info.plist")) | Set-Clipboard
   ```
   çıxan mətni yapışdırın, **Secret** işarələyin.
6. **Start new build** → workflow `ios-appstore`. ~15–20 dəq sonra build TestFlight-da görünür.

## 6. Test və göndərmə
1. iPhone-a **TestFlight** tətbiqini yükləyin → build-i quraşdırın → giriş, xəritə, ONLINE, push-u yoxlayın.
2. App Store Connect → versiya 1.0:
   - Ekran görüntüləri: **6.9"** (1320×2868 və ya 1290×2796) — ən azı 3 ədəd
   - Privacy Policy URL: `.../privacy-policy.html`
   - **App Privacy**: Ad/e-poçt/telefon, Dəqiq yer (App Functionality), Cihaz ID
   - **App Review → Sign-in required**: test kuryer hesabı (e-poçt + şifrə) mütləq verin
   - Notes: “Courier app for BakuGo delivery platform. Couriers are approved by admin; demo account provided.”
3. **Add for Review → Submit**.

## Server tərəfi (push göndərən yer — admin/Cloud Function)
iOS-a çatması üçün FCM mesajında `notification` bloku olmalıdır (yalnız `webpush` kifayət etmir):
```js
await admin.messaging().send({
  token: courier.fcmToken,
  notification: { title: "Yeni sifariş", body: "Restoran: ..." },
  apns: { payload: { aps: { sound: "default" } } },
  webpush: { /* köhnə veb parametrləri qala bilər */ }
});
```

## Öz Mac-ınızda yığmaq istəsəniz
```bash
npm install
npx cap add ios
cp ~/Downloads/GoogleService-Info.plist ios/App/App/
npm run ios:assets && npm run ios:configure && npx cap sync ios
npx cap open ios      # Xcode → Signing: Team seçin → Product → Archive → Distribute
```

## Yeniləmə
`www/index.html`-i dəyişin → GitHub-a push → Codemagic avtomatik yeni build verir
(versiyanı artırmaq üçün `codemagic.yaml` → `APP_VERSION`).

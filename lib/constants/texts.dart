class AppTexts {
  static bool isEnglish = false;

  // --- Auth & General ---
  static String get loginTitle => isEnglish ? "Welcome to Yuvam" : "Yuvam'a Hoş Geldin";
  static String get loginSubtitle => isEnglish ? "Start planning your dream home." : "Hayalindeki yuvayı planlamaya başla.";
  static String get registerTitle => isEnglish ? "Create New Account" : "Yeni Hesap Oluştur";
  static String get registerSubtitle => isEnglish ? "Create your free account and start planning." : "Ücretsiz hesabını oluştur ve planlamaya geç.";
  static String get emailHint => isEnglish ? "Email Address" : "E-posta Adresi";
  static String get passwordHint => isEnglish ? "Password" : "Şifre";
  static String get nameHint => isEnglish ? "Your Name" : "Adınız";
  static String get surnameHint => isEnglish ? "Your Surname" : "Soyadınız";
  static String get loginBtn => isEnglish ? "Login" : "Giriş Yap";
  static String get registerBtn => isEnglish ? "Register" : "Kayıt Ol";
  static String get noAccount => isEnglish ? "Don't have an account? Register" : "Hesabın yok mu? Kayıt Ol";
  static String get welcomePrefix => isEnglish ? "Welcome" : "Hoş geldin";
  static String get logout => isEnglish ? "Logout" : "Çıkış Yap";

  // --- Onboarding ---
  static String get onboardTitle => isEnglish ? "Let's Create Your Plans ✨" : "Planlarını Oluşturalım ✨";
  static String get onboardInfo => isEnglish ? "Yuvam manages your budget, lists your items and counts down for you." : "Yuvam senin için bütçeni yönetir, eşyalarını listeler ve geri sayım yapar.";
  static String get onboardStartTitle => isEnglish ? "Let's Start the Process ✨" : "Süreci Başlatalım ✨";
  static String get skipBtn => isEnglish ? "Skip for Now" : "Şimdilik Geç";
  static String get partnerSectionTitle => isEnglish ? "Are you already part of a plan?" : "Zaten bir planın parçası mısın?";
  static String get partnerCodeHint => isEnglish ? "Enter partner code (Optional)" : "Eşinin gönderdiği kodu gir (Opsiyonel)";
  static String get ownPlanSectionTitle => isEnglish ? "Or create your own plan:" : "Veya kendi planını oluştur:";
  static String get dateNotSet => isEnglish ? "Date Not Set (Click to select)" : "Tarih Belli Değil (Seçmek için tıkla)";
  static String get continueBtn => isEnglish ? "Continue" : "Devam Et";
  static String get finishBtn => isEnglish ? "Let's Get Started 🚀" : "Hadi Başlayalım 🚀";
  static String get footerNote => isEnglish ? "* You can change these dates later in settings." : "* Bu tarihleri daha sonra ayarlardan değiştirebilirsin.";

  // --- Navigation ---
  static String get navDashboard => isEnglish ? "Dashboard" : "Özet";
  static String get navWallet => isEnglish ? "Wallet" : "Cüzdan";
  static String get navServices => isEnglish ? "Services" : "Hizmetler";
  static String get navShopping => isEnglish ? "Shopping" : "Alışveriş"; // Renamed from navItems
  static String get navTasks => isEnglish ? "Tasks" : "Görevler"; // Added
  static String get navUs => isEnglish ? "Us" : "Biz";

  // --- Dashboard ---
  static String get dashboardTitle => isEnglish ? "Dashboard" : "Özet";
  static String get goodMorning => isEnglish ? "Good Morning" : "Günaydın";
  static String get goodAfternoon => isEnglish ? "Good Afternoon" : "İyi Günler";
  static String get goodEvening => isEnglish ? "İyi Akşamlar" : "İyi Akşamlar";
  static String get daysUntilEvent => isEnglish ? "days until" : "gün kaldı";
  static String get upcomingPayments => isEnglish ? "Upcoming Payments" : "Yaklaşan Ödemeler";
  static String get paymentsToBeMade => isEnglish ? "Payments to be Made" : "Yapılacak Ödemeler";
  static String get pendingTasks => isEnglish ? "Pending Tasks" : "Bekleyen Görevler";
  static String get recentActivity => isEnglish ? "Recent Activity" : "Son Aktiviteler";
  static String get motivationalNotes => isEnglish ? "Notes for You" : "Sana Notlar";
  static String get noUpcomingPayments => isEnglish ? "No upcoming payments" : "Yaklaşan ödeme yok";
  static String get noPendingTasks => isEnglish ? "No pending tasks" : "Bekleyen görev yok";
  static String get noNotes => isEnglish ? "No notes yet" : "Henüz not yok";
  static String get viewAll => isEnglish ? "View All" : "Tümünü Gör";
  static String get quickActions => isEnglish ? "Quick Actions" : "Hızlı İşlemler";

  // --- Wallet ---
  static String get walletTitle => isEnglish ? "Wallet" : "Cüzdan";
  static String get totalExpenses => isEnglish ? "Total Expenses" : "Toplam Gider";
  static String get totalPaid => isEnglish ? "Total Paid" : "Ödenen Tutar";
  static String get remainingDebt => isEnglish ? "Remaining Debt" : "Kalan Borç";
  static String get paymentCalendar => isEnglish ? "Payment Calendar" : "Ödeme Takvimi";
  static String get paymentHistory => isEnglish ? "Payment History" : "Ödeme Geçmişi";
  static String get noPayments => isEnglish ? "No payments yet" : "Henüz ödeme yok";

  // --- Services ---
  static String get servicesTitle => isEnglish ? "Services" : "Hizmetler";
  static String get addService => isEnglish ? "Add Service" : "Hizmet Ekle";
  static String get serviceCategories => isEnglish ? "Categories" : "Kategoriler";
  static String get categoryBeauty => isEnglish ? "Beauty" : "Güzellik";
  static String get categoryVenue => isEnglish ? "Venue" : "Mekan";
  static String get categoryPhotography => isEnglish ? "Photography" : "Fotoğraf";
  static String get categoryCatering => isEnglish ? "Catering" : "Yemek";
  static String get categoryMusic => isEnglish ? "Music" : "Müzik";
  static String get categoryOther => isEnglish ? "Other" : "Diğer";
  static String get categoryGeneral => isEnglish ? "General" : "Genel";
  static String get categoryWedding => isEnglish ? "Wedding" : "Düğün";
  static String get remaining => isEnglish ? "Remaining" : "Kalan";
  static String get serviceNameHint => isEnglish ? "Service name (e.g. Wedding Hall)" : "Hizmet adı (örn: Düğün Salonu)";
  static String get serviceCategoryHint => isEnglish ? "Select category" : "Kategori seç";
  static String get totalAmountHint => isEnglish ? "Total amount" : "Toplam tutar";
  static String get depositHint => isEnglish ? "Deposit paid" : "Ödenen kapora";
  static String get paymentDeadlineHint => isEnglish ? "Payment deadline" : "Ödeme tarihi";
  static String get contactPhone => isEnglish ? "Phone" : "Telefon";
  static String get contactEmail => isEnglish ? "Email" : "E-posta";
  static String get contactWebsite => isEnglish ? "Website" : "Web Sitesi";
  static String get location => isEnglish ? "Location" : "Konum";
  static String get documents => isEnglish ? "Documents" : "Belgeler";
  static String get contract => isEnglish ? "Contract" : "Sözleşme";
  static String get invoice => isEnglish ? "Invoice" : "Fatura";
  static String get addPayment => isEnglish ? "Add Payment" : "Ödeme Ekle";
  static String get paymentAmount => isEnglish ? "Payment amount" : "Ödeme tutarı";
  static String get paymentNote => isEnglish ? "Note (optional)" : "Not (opsiyonel)";
  static String get noServices => isEnglish ? "No services yet. Add your first service!" : "Henüz hizmet yok. İlk hizmetini ekle!";

  // --- Items / Shopping ---
  static String get shoppingTitle => isEnglish ? "Shopping" : "Alışveriş"; // Renamed from itemsTitle
  static String get itemsTitle => isEnglish ? "Items" : "Eşyalar"; // Kept for backward compat or specific usage if needed, but intended to be replaced
  static String get addItem => isEnglish ? "Add Item" : "Eşya Ekle";
  static String get addRoom => isEnglish ? "Add Room" : "Oda Ekle";
  static String get roomNameHint => isEnglish ? "Room name (e.g. Kitchen)" : "Oda adı (örn: Mutfak)";
  static String get priceHint => isEnglish ? "Price (Optional)" : "Fiyat (Opsiyonel)";
  static String get purchased => isEnglish ? "Purchased" : "Satın Alındı";
  static String get notPurchased => isEnglish ? "Not Purchased" : "Alınmadı";
  static String get uploadInvoice => isEnglish ? "Upload Invoice" : "Fatura Yükle";
  static String get uploadWarranty => isEnglish ? "Upload Warranty" : "Garanti Belgesi Yükle";
  static String get notes => isEnglish ? "Notes" : "Notlar";
  static String get noRooms => isEnglish ? "No rooms yet. Create your first room!" : "Henüz oda yok. İlk odanı oluştur!";
  static String get itemNameHint => isEnglish ? "Item Name" : "Eşya Adı";
  static String get itemCategoryHint => isEnglish ? "Category" : "Kategori";
  static String get quantityHint => isEnglish ? "Quantity" : "Adet";
  static String get costHint => isEnglish ? "Cost per item" : "Birim fiyat";
  static String get supplierHint => isEnglish ? "Supplier" : "Tedarikçi";
  static String get notesHint => isEnglish ? "Notes" : "Notlar";
  static String get noItems => isEnglish ? "No items yet.\nStart adding items for your wedding!" : "Henüz eşya yok.\nDüğününüz için eşya eklemeye başlayın!";
  static String get statusToBuy => isEnglish ? "To Buy" : "Alınacak";
  static String get statusBought => isEnglish ? "Bought" : "Alındı";


  // --- Us Page ---
  static String get usTitle => isEnglish ? "Us" : "Biz";
  static String get daysUntil => isEnglish ? "days until" : "gün kaldı";
  static String get relationshipDuration => isEnglish ? "Together for" : "Birlikte";
  static String get years => isEnglish ? "years" : "yıl";
  static String get days => isEnglish ? "days" : "gün";
  static String get leaveNote => isEnglish ? "Leave a note for your partner" : "Eşine not bırak";
  static String get writeNote => isEnglish ? "Write your note..." : "Notunu yaz...";
  static String get sendNote => isEnglish ? "Send" : "Gönder";
  static String get partnerNotes => isEnglish ? "Notes from Partner" : "Eşinden Notlar";
  static String get connectionSettings => isEnglish ? "Connection Settings" : "Bağlantı Ayarları";
  static String get invitePartner => isEnglish ? "Invite Partner" : "Eşini Davet Et";
  static String get inviteDesc => isEnglish ? "Share this code with your partner" : "Bu kodu eşinle paylaş";
  static String get copySuccess => isEnglish ? "Code copied!" : "Kod kopyalandı!";
  static String get partnerCodeInputHint => isEnglish ? "Enter partner code" : "Eş kodunu gir";
  static String get pairButton => isEnglish ? "Connect" : "Bağlan";
  static String get partnerConnected => isEnglish ? "Connected to partner ❤️" : "Eşinle bağlısın ❤️";
  static String get manageInSettings => isEnglish ? "Manage in settings" : "Ayarlardan yönet";

  // --- To-Do ---
  static String get tasksTitle => isEnglish ? "Tasks" : "Görevler"; // Added
  static String get todoTitle => isEnglish ? "To-Do" : "Yapılacaklar";

  static String get noTasks => isEnglish ? "No tasks yet. Start planning your wedding!" : "Henüz görev yok. Düğününü planlamaya başla!";
  static String get addTask => isEnglish ? "Add Task" : "Görev Ekle";
  static String get taskNameHint => isEnglish ? "Task Name" : "Görev Adı";
  static String get taskCategoryHint => isEnglish ? "Category" : "Kategori";
  static String get dueDateHint => isEnglish ? "Due Date" : "Son Tarih";
  static String get priorityHint => isEnglish ? "Priority" : "Öncelik";
  static String get assignedToHint => isEnglish ? "Assigned To" : "Atanan Kişi";
  static String get taskCompleted => isEnglish ? "Completed" : "Tamamlandı";
  static String get taskPending => isEnglish ? "Pending" : "Bekliyor";
  static String get deleteTaskConfirm => isEnglish ? "Delete this task?" : "Bu görevi sil?";
  static String get taskOverdue => isEnglish ? "Overdue" : "Gecikmiş";
  static String get taskDueToday => isEnglish ? "Due Today" : "Bugün";
  static String get taskDueTomorrow => isEnglish ? "Due Tomorrow" : "Yarın";

  // --- Us Page ---
  static String get connected => isEnglish ? "Connected" : "Bağlı";
  static String get notConnected => isEnglish ? "Not Connected" : "Bağlı Değil";
  static String get partnerCode => isEnglish ? "Partner Code" : "Partner Kodu";
  static String get shareCode => isEnglish ? "Share Code" : "Kodu Paylaş";
  static String get copyCode => isEnglish ? "Copy Code" : "Kodu Kopyala";
  static String get codeCopied => isEnglish ? "Code copied!" : "Kod kopyalandı!";
  static String get disconnect => isEnglish ? "Disconnect" : "Bağlantıyı Kes";
  static String get disconnectConfirm => isEnglish ? "Are you sure you want to disconnect?" : "Bağlantıyı kesmek istediğinize emin misiniz?";
  static String get yourCode => isEnglish ? "Your Code" : "Senin Kodun";
  static String get partnerName => isEnglish ? "Partner" : "Eşin";

  // --- Notes ---
  static String get ourNotes => isEnglish ? "Our Notes" : "Notlarımız";
  static String get addNote => isEnglish ? "Add Note" : "Not Ekle";
  static String get viewAllNotes => isEnglish ? "View All" : "Tümünü Gör";
  static String get noteHint => isEnglish ? "Write a sweet message..." : "Tatlı bir mesaj yaz...";
  static String get noteAdded => isEnglish ? "Note added!" : "Not eklendi!";
  static String get deleteNote => isEnglish ? "Delete Note" : "Notu Sil";
  static String get deleteNoteConfirm => isEnglish ? "Delete this note?" : "Bu notu silmek istediğinize emin misiniz?";
  static String get noteDeleted => isEnglish ? "Note deleted" : "Not silindi";
  static String get cannotDeleteNote => isEnglish ? "You can only delete your own notes" : "Sadece kendi notlarını silebilirsin";
  static String get selectEmoji => isEnglish ? "Select Emoji" : "Emoji Seç";
  static String get justNow => isEnglish ? "Just now" : "Az önce";
  static String get minutesAgo => isEnglish ? "minutes ago" : "dakika önce";
  static String get hoursAgo => isEnglish ? "hours ago" : "saat önce";
  static String get daysAgo => isEnglish ? "days ago" : "gün önce";

  // --- Settings ---
  static String get settingsTitle => isEnglish ? "Settings" : "Ayarlar";
  static String get settingsThemeSection => isEnglish ? "Appearance" : "Görünüm";
  static String get settingsDarkMode => isEnglish ? "Dark Mode" : "Koyu Tema";
  static String get settingsSystemDefault => isEnglish ? "System Default" : "Sistem Varsayılanı";
  static String get settingsLanguageSection => isEnglish ? "Language" : "Dil";
  static String get settingsLanguage => isEnglish ? "App Language" : "Uygulama Dili";
  static String get settingsAccountSection => isEnglish ? "Account" : "Hesap";
  static String get settingsChangeEmail => isEnglish ? "Change Email" : "E-posta Değiştir";
  static String get settingsChangePassword => isEnglish ? "Change Password" : "Şifre Değiştir";
  static String get settingsDeleteAccount => isEnglish ? "Delete Account" : "Hesabı Sil";
  static String get settingsDangerZone => isEnglish ? "Danger Zone" : "Tehlikeli Bölge";
  static String get settingsAreYouSureDelete => isEnglish ? "This action cannot be undone. Delete account?" : "Bu işlem geri alınamaz. Hesabı sil?";
  static String get settingsYesDelete => isEnglish ? "Yes, delete" : "Evet, sil";
  static String get settingsNoKeep => isEnglish ? "No, keep it" : "Hayır, kalsın";
  static String get settingsEmailHint => isEnglish ? "New email address" : "Yeni e‑posta adresi";
  static String get settingsPasswordHint => isEnglish ? "New password" : "Yeni şifre";
  static String get settingsSaveBtn => isEnglish ? "Save" : "Kaydet";
  static String get settingsUpdated => isEnglish ? "Updated successfully." : "Başarıyla güncellendi.";
  static String get settingsDeleteErrorRecentLogin => isEnglish ? "Please re‑login and try again." : "Lütfen tekrar giriş yapıp yeniden dene.";
  static String get settingsPartnerSection => isEnglish ? "Partner Connection" : "Eş Bağlantısı";
  static String get settingsDisconnectPartner => isEnglish ? "Disconnect Partner" : "Eş Bağlantısını Kaldır";
  static String get settingsPartnerStatus => isEnglish ? "Connected to partner" : "Eşinle bağlısın";
  static String get settingsNoPartner => isEnglish ? "No partner connected" : "Eş bağlantısı yok";
  static String get disconnectConfirmTitle => isEnglish ? "Disconnect Partner?" : "Eş Bağlantısını Kaldır?";
  static String get disconnectDataQuestion => isEnglish ? "What should happen to your data?" : "Verilerinize ne olsun?";
  static String get disconnectKeepData => isEnglish ? "Keep my data" : "Verilerimi Koru";
  static String get disconnectDeleteData => isEnglish ? "Start fresh" : "Sıfırdan Başla";
  static String get disconnectKeepDataDesc => isEnglish ? "Copy all data to your new personal space" : "Tüm verileri yeni kişisel alanına kopyala";
  static String get disconnectDeleteDataDesc => isEnglish ? "Remove all data and start with a clean slate" : "Tüm verileri sil ve temiz başla";
  static String get disconnectSuccess => isEnglish ? "Partner disconnected successfully" : "Eş bağlantısı başarıyla kaldırıldı";

  // --- Events ---
  static String get eventEngagement => isEnglish ? "Engagement" : "Nişan";
  static String get eventHenna => isEnglish ? "Henna Night" : "Kına Gecesi";
  static String get eventWedding => isEnglish ? "Wedding" : "Düğün";
  static String get selectEvent => isEnglish ? "Select Event" : "Etkinlik Seç";
  static String get eventDate => isEnglish ? "Event Date" : "Etkinlik Tarihi";
  static String get editEvents => isEnglish ? "Edit Event Dates" : "Etkinlik Tarihlerini Düzenle";
  
  // --- Profile ---
  static String get profileTitle => isEnglish ? "Profile" : "Profil";

  // --- Errors ---
  static String get authError => isEnglish ? "Auth error!" : "Oturum hatası!";
  static String get invalidCodeError => isEnglish ? "Invalid code!" : "Geçersiz kod!";
  static String get selfPairError => isEnglish ? "You can't pair with yourself!" : "Kendi kodunla eşleşemezsin!";
  static String get alreadyPairedError => isEnglish ? "This partner is already connected!" : "Bu eş zaten bağlı!";
  static String get generalError => isEnglish ? "An error occurred:" : "Bir hata oluştu:";
  static String get pairingSuccess => isEnglish ? "Successfully connected! 🎉" : "Başarıyla bağlandı! 🎉";

  // --- Common ---
  static String get cancelBtn => isEnglish ? "Cancel" : "İptal";
  static String get addBtn => isEnglish ? "Add" : "Ekle";
  static String get saveBtn => isEnglish ? "Save" : "Kaydet";
  static String get deleteBtn => isEnglish ? "Delete" : "Sil";
  static String get editBtn => isEnglish ? "Edit" : "Düzenle";
  static String get confirmBtn => isEnglish ? "Confirm" : "Onayla";
  static String get yesBtn => isEnglish ? "Yes" : "Evet";
  static String get noBtn => isEnglish ? "No" : "Hayır";
}
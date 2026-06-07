import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/user_profile.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  // ── Mock Data (siap diganti Repository pattern nanti) ─────────────────────
  static final UserProfile _mockProfile = UserProfile(
    id: 'user_001',
    username: 'budisantoso_jkt',
    displayName: 'Budi Santoso',
    avatarUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300',
    domicile: 'Jakarta Selatan, DKI Jakarta',
    isVerifiedCitizen: true,
    gamificationTitle: 'Pahlawan Aspal',
    civicPoints: 2_840,
    reportsSolved: 14,
    upvotesGiven: 87,
    totalReports: 23,
    availablePointsForRedeem: 1_200,
    myReports: [
      const UserReport(
        id: 'r1',
        title: 'Lubang Dalam di Jl. Ampera Raya',
        category: 'JALAN',
        imageUrl:
            'https://images.unsplash.com/photo-1515162305285-0293e4767cc2?w=400',
        timeAgo: '2 hari lalu',
        upvotes: 142,
        status: ReportStatus.solved,
      ),
      const UserReport(
        id: 'r2',
        title: 'Lampu PJU Padam Gang Mawar',
        category: 'PJU',
        imageUrl:
            'https://images.unsplash.com/photo-1509024640742-b67bf6b45084?w=400',
        timeAgo: '5 hari lalu',
        upvotes: 58,
        status: ReportStatus.inProgress,
      ),
      const UserReport(
        id: 'r3',
        title: 'Selokan Mampet Jl. Kemang Timur',
        category: 'DRAINASE',
        imageUrl:
            'https://images.unsplash.com/photo-1504386106-b41949b7e9a8?w=400',
        timeAgo: '1 minggu lalu',
        upvotes: 31,
        status: ReportStatus.waitingReview,
      ),
      const UserReport(
        id: 'r4',
        title: 'Trotoar Rusak Jl. Fatmawati',
        category: 'TROTOAR',
        imageUrl:
            'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=400',
        timeAgo: '2 minggu lalu',
        upvotes: 76,
        status: ReportStatus.solved,
      ),
      const UserReport(
        id: 'r5',
        title: 'Pohon Tumbang Jl. Sisingamangaraja',
        category: 'POHON',
        imageUrl:
            'https://images.unsplash.com/photo-1604685601600-a78e7f27e8a1?w=400',
        timeAgo: '3 minggu lalu',
        upvotes: 203,
        status: ReportStatus.solved,
      ),
    ],
    supportedReports: [
      const SupportedReport(
        id: 's1',
        title: 'Banjir Rutin di Underpass Mampang',
        authorName: 'Siti Aminah',
        authorAvatarUrl:
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
        category: 'BANJIR',
        imageUrl:
            'https://images.unsplash.com/photo-1547683905-f686c993aae5?w=400',
        timeAgo: '1 hari lalu',
        upvotes: 315,
        status: ReportStatus.inProgress,
        isSaved: false,
      ),
      const SupportedReport(
        id: 's2',
        title: 'SPBU Ilegal di Pinggir Jalan',
        authorName: 'Rizky Pratama',
        authorAvatarUrl:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        category: 'LAINNYA',
        imageUrl:
            'https://images.unsplash.com/photo-1542773998-9325f0a098d7?w=400',
        timeAgo: '3 hari lalu',
        upvotes: 87,
        status: ReportStatus.waitingReview,
        isSaved: true,
      ),
      const SupportedReport(
        id: 's3',
        title: 'Gerbang Tol Rusak Macet Panjang',
        authorName: 'Dewi Kurnia',
        authorAvatarUrl:
            'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150',
        category: 'JALAN',
        imageUrl:
            'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=400',
        timeAgo: '1 minggu lalu',
        upvotes: 421,
        status: ReportStatus.solved,
        isSaved: false,
      ),
    ],
    badges: [
      const Badge(
        id: 'b1',
        name: 'Pelopor Pertama',
        description: 'Buat laporan pertamamu',
        icon: '🏅',
        rarity: BadgeRarity.common,
        isUnlocked: true,
        unlockedAt: '12 Jan 2025',
      ),
      const Badge(
        id: 'b2',
        name: 'Pahlawan Aspal',
        description: 'Miliki 5 laporan jalan yang diselesaikan',
        icon: '🛣️',
        rarity: BadgeRarity.rare,
        isUnlocked: true,
        unlockedAt: '15 Mar 2025',
      ),
      const Badge(
        id: 'b3',
        name: 'Warga Aktif',
        description: 'Berikan 50 dukungan ke laporan lain',
        icon: '🤝',
        rarity: BadgeRarity.rare,
        isUnlocked: true,
        unlockedAt: '02 Apr 2025',
      ),
      const Badge(
        id: 'b4',
        name: 'Suara Kota',
        description: 'Dapatkan 500+ total upvote pada laporanmu',
        icon: '📣',
        rarity: BadgeRarity.epic,
        isUnlocked: true,
        unlockedAt: '20 Mei 2025',
      ),
      const Badge(
        id: 'b5',
        name: 'Guardian Lampu',
        description: 'Selesaikan 5 laporan PJU / lampu jalan',
        icon: '💡',
        rarity: BadgeRarity.epic,
        isUnlocked: false,
      ),
      const Badge(
        id: 'b6',
        name: 'Legenda Kota',
        description: 'Miliki 1000+ Civic Points dan 20 laporan selesai',
        icon: '👑',
        rarity: BadgeRarity.legendary,
        isUnlocked: false,
      ),
    ],
  );

  // ── Reward Catalog ────────────────────────────────────────────────────────
  static final List<RedeemReward> _rewards = [
    const RedeemReward(
      id: 'rw1',
      name: 'Voucher Grab 25K',
      description: 'Tukar 500 poin untuk voucher transportasi',
      pointsCost: 500,
      icon: '🚗',
      isAvailable: true,
    ),
    const RedeemReward(
      id: 'rw2',
      name: 'Sertifikat Digital',
      description: 'Pengakuan resmi sebagai Warga Aktif JAGAIN',
      pointsCost: 300,
      icon: '📜',
      isAvailable: true,
    ),
    const RedeemReward(
      id: 'rw3',
      name: 'Diskon PDAM 10%',
      description: 'Diskon tagihan air bulan ini',
      pointsCost: 1000,
      icon: '💧',
      isAvailable: true,
    ),
    const RedeemReward(
      id: 'rw4',
      name: 'Token Listrik 50K',
      description: 'Tukar 2000 poin untuk token listrik',
      pointsCost: 2000,
      icon: '⚡',
      isAvailable: false,
    ),
  ];

  // ── BLoC ──────────────────────────────────────────────────────────────────
  ProfileBloc() : super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<SwitchProfileTab>(_onSwitchProfileTab);
    on<RedeemPoints>(_onRedeemPoints);
  }

  Future<void> _onLoadProfile(
      LoadProfile event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    await Future.delayed(const Duration(milliseconds: 400));
    emit(ProfileLoaded(profile: _mockProfile));
  }

  void _onSwitchProfileTab(
      SwitchProfileTab event, Emitter<ProfileState> emit) {
    if (state is ProfileLoaded) {
      emit((state as ProfileLoaded).copyWith(activeTabIndex: event.tabIndex));
    }
  }

  void _onRedeemPoints(RedeemPoints event, Emitter<ProfileState> emit) {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      final reward = _rewards.firstWhere((r) => r.id == event.rewardId);
      final newPoints =
          currentState.profile.availablePointsForRedeem - reward.pointsCost;

      // Update profile dengan poin baru
      final updatedProfile = UserProfile(
        id: currentState.profile.id,
        username: currentState.profile.username,
        displayName: currentState.profile.displayName,
        avatarUrl: currentState.profile.avatarUrl,
        domicile: currentState.profile.domicile,
        isVerifiedCitizen: currentState.profile.isVerifiedCitizen,
        gamificationTitle: currentState.profile.gamificationTitle,
        civicPoints: currentState.profile.civicPoints,
        reportsSolved: currentState.profile.reportsSolved,
        upvotesGiven: currentState.profile.upvotesGiven,
        totalReports: currentState.profile.totalReports,
        myReports: currentState.profile.myReports,
        supportedReports: currentState.profile.supportedReports,
        badges: currentState.profile.badges,
        availablePointsForRedeem: newPoints < 0 ? 0 : newPoints,
      );

      emit(currentState.copyWith(
        profile: updatedProfile,
        redeemSuccessMessage: '${reward.name} berhasil ditukar! 🎉',
      ));
    }
  }

  List<RedeemReward> get rewards => _rewards;
}

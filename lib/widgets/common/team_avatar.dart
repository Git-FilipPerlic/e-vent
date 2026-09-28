import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Ikonica pod kojom te ekipa prepoznaje.
///
/// **Nisu fotografije** (odluka od 28. septembra 2026). Aplikacija nije
/// pravljena za profilne slike, a prave slike bi tražile Firebase Storage,
/// koji se preko besplatnog nivoa plaća. Umesto toga postoji dvanaest
/// gotovih ikonica: jarka boja i jednostavan simbol.
///
/// Ne zauzimaju **ni bajt** u APK-u — crtaju se iz ugrađenih Material
/// simbola, pa su oštre na svakom ekranu i u svakoj veličini. Kad firma
/// jednom bude plaćala Storage, prave slike se dodaju pored ovoga, bez
/// diranja onoga što već radi.
class TeamAvatar {
  const TeamAvatar({required this.id, required this.icon, required this.color});

  /// Ono što se pamti uz korisnika. Kratko i stalno — ime ikonice se sme
  /// menjati, id ne.
  final String id;

  final IconData icon;
  final Color color;
}

/// Spisak ikonica koje se nude. Redosled je i redosled u biraču.
abstract final class TeamAvatars {
  static const List<TeamAvatar> all = [
    TeamAvatar(
      id: 'zvezda',
      icon: Icons.star_rounded,
      color: AppColors.avatarYellow,
    ),
    TeamAvatar(
      id: 'vatra',
      icon: Icons.local_fire_department_rounded,
      color: AppColors.avatarRed,
    ),
    TeamAvatar(
      id: 'nota',
      icon: Icons.music_note_rounded,
      color: AppColors.avatarBlue,
    ),
    TeamAvatar(
      id: 'grom',
      icon: Icons.bolt_rounded,
      color: AppColors.avatarOrange,
    ),
    TeamAvatar(
      id: 'srce',
      icon: Icons.favorite_rounded,
      color: AppColors.avatarPink,
    ),
    TeamAvatar(
      id: 'raketa',
      icon: Icons.rocket_launch_rounded,
      color: AppColors.avatarPurple,
    ),
    TeamAvatar(
      id: 'list',
      icon: Icons.eco_rounded,
      color: AppColors.avatarGreen,
    ),
    TeamAvatar(
      id: 'sunce',
      icon: Icons.wb_sunny_rounded,
      color: AppColors.avatarYellow,
    ),
    TeamAvatar(
      id: 'kombi',
      icon: Icons.airport_shuttle_rounded,
      color: AppColors.avatarBlue,
    ),
    TeamAvatar(
      id: 'sapa',
      icon: Icons.pets_rounded,
      color: AppColors.avatarOrange,
    ),
    TeamAvatar(
      id: 'balon',
      icon: Icons.celebration_rounded,
      color: AppColors.avatarPink,
    ),
    TeamAvatar(
      id: 'sijalica',
      icon: Icons.lightbulb_rounded,
      color: AppColors.avatarGreen,
    ),
  ];

  /// Ikonica po id-ju. **Nepoznat ili prazan id daje prvu** — čovek bez
  /// izabrane ikonice se i dalje nacrta, nikad se ne puca.
  static TeamAvatar byId(String? id) {
    for (final avatar in all) {
      if (avatar.id == id) return avatar;
    }
    return all.first;
  }
}

/// Kružić sa ikonicom člana ekipe.
class TeamAvatarDot extends StatelessWidget {
  const TeamAvatarDot({super.key, required this.avatarId, this.size = 32});

  final String? avatarId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final avatar = TeamAvatars.byId(avatarId);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: avatar.color, shape: BoxShape.circle),
      child: Icon(
        avatar.icon,
        size: size * 0.58,
        // Simbol je uvek beo: jarke podloge su tamne taman toliko da beli
        // simbol na svakoj od njih ostane čitak.
        color: Colors.white,
      ),
    );
  }
}

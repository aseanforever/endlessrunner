import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '/game/enemy.dart';
import '/game/dino_run.dart';
import '/models/player_model.dart';
import 'audio_manager.dart';

enum DinoAnimationStates {
  idle,
  hit,
}

class Dino extends SpriteAnimationGroupComponent<DinoAnimationStates>
    with CollisionCallbacks, HasGameReference<DinoRun> {
  static final _animationMap = {
    DinoAnimationStates.idle: SpriteAnimationData.sequenced(
      amount: 4,
      stepTime: 0.1,
      textureSize: Vector2.all(24),
    ),
    DinoAnimationStates.hit: SpriteAnimationData.sequenced(
      amount: 3,
      stepTime: 0.1,
      textureSize: Vector2.all(24),
      texturePosition: Vector2(14 * 24, 0),
    ),
  };

  double yMax = 0.0;

  double speedY = 0.0;

  final Timer _hitTimer = Timer(1);

  static const double gravity = 800;

  final PlayerModel playerModel;

  bool isHit = false;

  Dino(Image image, this.playerModel)
      : super.fromFrameData(image, _animationMap);

  @override
  void onMount() {
    _reset();

    add(
      RectangleHitbox.relative(
        Vector2(0.5, 0.7),
        parentSize: size,
        position: Vector2(size.x * 0.5, size.y * 0.3) / 2,
      ),
    );
    yMax = y;

    _hitTimer.onTick = () {
      isHit = false;
    };

    super.onMount();
  }

  @override
  void update(double dt) {
    speedY += gravity * dt;

    y += speedY * dt;

    if (isOnGround) {
      y = yMax;
      speedY = 0.0;
    }

    _hitTimer.update(dt);
    super.update(dt);
  }

  @override
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Enemy && !isHit) {
      hit(other);
    }
    super.onCollision(intersectionPoints, other);
  }

  bool get isOnGround => (y >= yMax);

  void jump() {
    if (isOnGround) {
      speedY = -300;
      current = DinoAnimationStates.idle;
      AudioManager.instance.playSfx('jump14.wav');
    }
  }

  void hit(Enemy enemy) {
    isHit = true;
    AudioManager.instance.playSfx('hurt7.wav');
    current = DinoAnimationStates.hit;
    _hitTimer.start();

    playerModel.decreaseHealth(enemy.enemyData.damage);
  }

  void _reset() {
    if (isMounted) {
      removeFromParent();
    }
    anchor = Anchor.bottomLeft;
    position = Vector2(32, game.virtualSize.y - 22);
    size = Vector2.all(24);

    isHit = false;
    speedY = 0.0;
  }
}

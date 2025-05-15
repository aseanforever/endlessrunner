import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '/game/dino_run.dart';
import '/models/enemy_model.dart';

class Enemy extends SpriteAnimationComponent
    with CollisionCallbacks, HasGameReference<DinoRun> {
  final EnemyData enemyData;

  Enemy(this.enemyData) {
    animation = SpriteAnimation.fromFrameData(
      enemyData.image,
      SpriteAnimationData.sequenced(
        amount: enemyData.nFrames,
        stepTime: enemyData.stepTime,
        textureSize: enemyData.textureSize,
      ),
    );
  }

  @override
  void onMount() {
    size *= 0.6;

    add(
      RectangleHitbox.relative(
        Vector2.all(0.8),
        parentSize: size,
        position: Vector2(size.x * 0.2, size.y * 0.2) / 2,
      ),
    );
    super.onMount();
  }

  @override
  @override
  void update(double dt) {
    position.x -= enemyData.speedX * dt;

    if (position.x < -enemyData.textureSize.x) {
      removeFromParent();

      game.playerModel.increaseScore(enemyData.damage);
    }

    super.update(dt);
  }
}

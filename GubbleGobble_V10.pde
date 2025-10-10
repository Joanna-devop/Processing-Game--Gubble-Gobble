// GUBBLE GOBBLE GAME FOR ASSESSMENT PART 1

// -------- 1. GLOBAL GAME STATE VARIABLES --------

// Game state management
final int START_SCREEN = 0;
final int PLAYING = 1;
final int GAME_OVER_SCREEN = 2;
final int GAME_WON_SCREEN = 3;
final int LEVEL_2 = 4;
final int LEVEL_3 = 5;

// Controls which screen the game is showing (start, playing, level won, etc.)
int gameState;

Goose playerGoose;

// Entity collections - using ArrayLists so entities can be added/removed during play
ArrayList<Platform> platforms;
ArrayList<Enemy> enemies;
ArrayList<Bubble> bubbles;
ArrayList<Egg> goldenEggs;

// Map and level data
// Map grid: 0 = empty, 1 = platform (rendered and collidable)
int[][] levelMap;

// Base tile size for positioning and collision
final int TILE_SIZE = 40;

// Score and progress tracking
int enemiesDefeated;
int totalEnemiesInLevel;
int eggsCollected;
int totalEggs;
int lives;

// Current level number (1–3)
int currentLevel;

// Offsets so the map is centred in the window
float mapOffsetX;
float mapOffsetY;



// -------- 2. SETUP FUNCTION --------

void setup() {
  size(800, 640); 
  gameState = START_SCREEN; // start on the title screen
  noSmooth(); // retro pixel look
  
  // Calculate map offsets so the level is centred in the window
  int mapPixelWidth = 20 * TILE_SIZE;
  int mapPixelHeight = 16 * TILE_SIZE;
  mapOffsetX = (width - mapPixelWidth) / 2.0;
  mapOffsetY = (height - mapPixelHeight) / 2.0;

  // Entity collections
  platforms = new ArrayList<Platform>();
  enemies = new ArrayList<Enemy>();
  bubbles = new ArrayList<Bubble>();
  goldenEggs = new ArrayList<Egg>();
  
  currentLevel = 1;
  
  // Create Gubble; final spawn position is handled in setupLevel1()
  playerGoose = new Goose(2 * TILE_SIZE + TILE_SIZE/2, 10 * TILE_SIZE + TILE_SIZE/2);
  
  // Load Level 1 (populates map and entities)
  setupLevel1();
}



// -------- 3. DRAW FUNCTION --------

// Show the right screen for the current game state
void draw() {
  switch (gameState) {
    case START_SCREEN:
      drawStartScreen();
      break;
    case PLAYING:
      playGame();
      break;
     case GAME_OVER_SCREEN:
       drawGameOverScreen();
       break;
      case GAME_WON_SCREEN:
        drawGameWonScreen();
        break;
      case LEVEL_2:   // playing state for Level 2
        playGame();
        break;
      case LEVEL_3:  // playing state for Level 3
        playGame();
        break;
  }
}
  
// -------- 4. GAME LOGIC & INITIALIZATION FUNCTIONS --------

// Game loop: draw background/map, update + render entities, then HUD on top

void playGame() {
  background(150, 200, 255);
  drawBackgroundDetails();
  drawLevelMap();
  
  // Player: update first, then render
  playerGoose.update();
  playerGoose.render();
  
  // Iterate backward so removing items doesn't skip elements
  for (int i = bubbles.size() - 1; i >=0; i--) {
    Bubble b = bubbles.get(i);                 
    b.update();
    b.render();
    
    if (b.state == b.ACTIVE) {
      // A bubble can trap at most one enemy
      for (Enemy e : enemies) {
        if (!e.isTrapped && b.checkEnemyHit(e)) {
          e.trap();
          b.state = b.TRAPPED_ENEMY;
          b.trappedEnemy = e;
          break;
        }
      }
    }
    
    // Remove bubbles that hit a wall or go off-screen (keep if carrying enemy)
    if (b.state == b.HIT_WALL 
      || b.position.x < mapOffsetX 
      || b.position.x > width - mapOffsetX 
      || b.position.y < mapOffsetY 
      || b.position.y > height - mapOffsetY) {
      if (b.state != b.TRAPPED_ENEMY) {
        bubbles.remove(i);
      }
    }
  }
  
  // Enemies: update, render, then resolve collisions
  for (int i = enemies.size() - 1; i >= 0; i--) {
    Enemy e = enemies.get(i);
    e.update();
    e.render();

    if (!e.isTrapped && e.checkCollision(playerGoose)) {
      playerGoose.takeHit();
      if (playerGoose.lives <= 0) {
        gameState = GAME_OVER_SCREEN;
      }
    }
    
    else if (e.isTrapped && e.checkCollision(playerGoose)) {
      // Pop trapped enemy and remove its bubble
      enemies.remove(i);
      enemiesDefeated++;
      
      for (int j = bubbles.size() - 1; j >= 0; j--) {
        if (bubbles.get(j).trappedEnemy == e) {
          bubbles.remove(j);
          break;
        }
      }
    }
  }
        
  // Eggs: draw and collect
  for (int i = goldenEggs.size() - 1; i >= 0; i--) {
    Egg egg = goldenEggs.get(i);
    egg.render();
    if (egg.isCollected(playerGoose)) {
      eggsCollected++;
      goldenEggs.remove(i);
    }
  }
    
  // If all enemies are defeated, trigger win screen
  if (enemiesDefeated >= totalEnemiesInLevel) {
    gameState = GAME_WON_SCREEN;
  }
  
  drawHUD(); // Always draw HUD last so it stays on top
   
}
  
// Reset all gameplay variables and reload Level 1
void resetGame() {
  lives = 3;
  enemiesDefeated = 0;
  eggsCollected = 0;
  
  // Clear all active objects
  platforms.clear();
  enemies.clear();
  bubbles.clear();
  goldenEggs.clear();
  
  // Recalculate map offsets before spawning anything
  int mapPixelWidth = 20 * TILE_SIZE;
  int mapPixelHeight = 16 * TILE_SIZE;
  mapOffsetX = (width - mapPixelWidth) / 2.0;
  mapOffsetY = (height - mapPixelHeight) / 2.0;

  playerGoose.reset(); // Reset position, velocity, etc.
  
  setupLevel1(); // Reload starting level
}
  
// Setup Level 1 layout and entities 
void setupLevel1() {
  lives = 3;
  playerGoose.lives = lives;
  currentLevel = 1;
  
  // Map grid: 0 = empty space, 1 = platform
  levelMap = new int[][] {
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
  };
  
  // Create platforms from map data
  for (int r = 0; r < levelMap.length; r++) {
    for (int c = 0; c < levelMap[0].length; c++) {
        float x = c * TILE_SIZE + TILE_SIZE / 2 + mapOffsetX;
        float y = r * TILE_SIZE + TILE_SIZE / 2 + mapOffsetY;
        if (levelMap[r][c] == 1) {
          platforms.add(new Platform(x, y, TILE_SIZE, TILE_SIZE));
        }
     }
   }
    
  // Add enemies (map offsets applied to positions)
  enemies.add(new Enemy(3 * TILE_SIZE + TILE_SIZE/2 + mapOffsetX, 14 * TILE_SIZE + TILE_SIZE/2 + mapOffsetY, "goblin"));
  enemies.add(new Enemy(15 * TILE_SIZE + TILE_SIZE/2 + mapOffsetX, 14 * TILE_SIZE + TILE_SIZE/2 + mapOffsetY, "goblin"));
  enemies.add(new Enemy(10 * TILE_SIZE + TILE_SIZE/2 + mapOffsetX, 5 * TILE_SIZE + TILE_SIZE/2 + mapOffsetY, "flying_goblin"));
  enemies.add(new Enemy(width / 2 + mapOffsetX, mapOffsetY + TILE_SIZE * 2, "tracker_goblin"));
  totalEnemiesInLevel = enemies.size();
  
  // Add collectible eggs
  goldenEggs.add(new Egg(5 * TILE_SIZE + TILE_SIZE/2 + mapOffsetX, 14 * TILE_SIZE + TILE_SIZE/2 + mapOffsetY)); // On ground
  goldenEggs.add(new Egg(8 * TILE_SIZE + TILE_SIZE/2 + mapOffsetX, 9 * TILE_SIZE + TILE_SIZE/2 + mapOffsetY)); // On middle platform
  goldenEggs.add(new Egg(12 * TILE_SIZE + TILE_SIZE/2 + mapOffsetX, 3 * TILE_SIZE + TILE_SIZE/2 + mapOffsetY)); // Near top
  totalEggs = goldenEggs.size();

  // Set player starting position
  playerGoose.position.set(2 * TILE_SIZE + TILE_SIZE/2 + mapOffsetX, 14 * TILE_SIZE + TILE_SIZE/2 + mapOffsetY);
}

void setupLevel2() {
  playerGoose.reset();
  playerGoose.lives = 3;
  currentLevel = 2;
  
  enemies.clear();
  bubbles.clear();
  goldenEggs.clear();
  platforms.clear();
  
  enemiesDefeated = 0;
  eggsCollected = 0;
  
  levelMap = new int[][] {
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
  };
  
  for (int r = 0; r < levelMap.length; r++) {
    for (int c = 0; c < levelMap[0].length; c++) {
        float x = c * TILE_SIZE + TILE_SIZE / 2 + mapOffsetX;
        float y = r * TILE_SIZE + TILE_SIZE / 2 + mapOffsetY;
        if (levelMap[r][c] == 1) {
          platforms.add(new Platform(x, y, TILE_SIZE, TILE_SIZE));
        }
     }
   }
   
  enemies.add(new Enemy(19 * TILE_SIZE + TILE_SIZE/2 + mapOffsetX, 14 * TILE_SIZE + TILE_SIZE/2 + mapOffsetY, "goblin"));
  enemies.add(new Enemy(10 * TILE_SIZE + TILE_SIZE/2 + mapOffsetX, 14 * TILE_SIZE + TILE_SIZE/2 + mapOffsetY, "goblin"));
  enemies.add(new Enemy(8 * TILE_SIZE + TILE_SIZE/2 + mapOffsetX, 10 * TILE_SIZE + TILE_SIZE/2 + mapOffsetY, "flying_goblin"));
  enemies.add(new Enemy(width / 2 + mapOffsetX, mapOffsetY + TILE_SIZE * 2, "tracker_goblin"));
  enemies.add(new Enemy(width / 2 + mapOffsetX + TILE_SIZE * 5, mapOffsetY + TILE_SIZE * 2, "tracker_goblin"));
  totalEnemiesInLevel = enemies.size();
  
  goldenEggs.add(new Egg(11 * TILE_SIZE + TILE_SIZE/2 + mapOffsetX, 1 * TILE_SIZE + TILE_SIZE/2 + mapOffsetY)); // On ground
  goldenEggs.add(new Egg(5 * TILE_SIZE + TILE_SIZE/2 + mapOffsetX, 3 * TILE_SIZE + TILE_SIZE/2 + mapOffsetY)); // On middle platform
  goldenEggs.add(new Egg(15 * TILE_SIZE + TILE_SIZE/2 + mapOffsetX, 6 * TILE_SIZE + TILE_SIZE/2 + mapOffsetY)); // Near top
  goldenEggs.add(new Egg(16 * TILE_SIZE + TILE_SIZE/2 + mapOffsetX, 14 * TILE_SIZE + TILE_SIZE/2 + mapOffsetY)); // Near top
  totalEggs = goldenEggs.size();

  playerGoose.position.set(2 * TILE_SIZE + TILE_SIZE/2 + mapOffsetX, 14 * TILE_SIZE + TILE_SIZE/2 + mapOffsetY);
}

void setupLevel3() {
  playerGoose.reset();
  playerGoose.lives = 3;
  currentLevel = 3;
  
  enemies.clear();
  bubbles.clear();
  goldenEggs.clear();
  platforms.clear();
  
  enemiesDefeated = 0;
  eggsCollected = 0;
  
  levelMap = new int[][] {
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
  };
  
  for (int r = 0; r < levelMap.length; r++) {
    for (int c = 0; c < levelMap[0].length; c++) {
        float x = c * TILE_SIZE + TILE_SIZE / 2 + mapOffsetX;
        float y = r * TILE_SIZE + TILE_SIZE / 2 + mapOffsetY;
        if (levelMap[r][c] == 1) {
          platforms.add(new Platform(x, y, TILE_SIZE, TILE_SIZE));
        }
     }
   }
   
  enemies.add(new Enemy(7 * TILE_SIZE + TILE_SIZE/2 + mapOffsetX, 14 * TILE_SIZE + TILE_SIZE/2 + mapOffsetY, "goblin"));
  enemies.add(new Enemy(9 * TILE_SIZE + TILE_SIZE/2 + mapOffsetX, 14 * TILE_SIZE + TILE_SIZE/2 + mapOffsetY, "goblin"));
  enemies.add(new Enemy(11 * TILE_SIZE + TILE_SIZE/2 + mapOffsetX, 14 * TILE_SIZE + TILE_SIZE/2 + mapOffsetY, "goblin"));
  enemies.add(new Enemy(8 * TILE_SIZE + TILE_SIZE/2 + mapOffsetX, 10 * TILE_SIZE + TILE_SIZE/2 + mapOffsetY, "flying_goblin"));
  enemies.add(new Enemy(16 * TILE_SIZE + TILE_SIZE/2 + mapOffsetX, 5 * TILE_SIZE + TILE_SIZE/2 + mapOffsetY, "flying_goblin"));
  enemies.add(new Enemy(2 * TILE_SIZE + TILE_SIZE/2 + mapOffsetX, 2 * TILE_SIZE + TILE_SIZE/2 + mapOffsetY, "flying_goblin"));
  enemies.add(new Enemy(width / 2 + mapOffsetX, mapOffsetY + TILE_SIZE * 2, "tracker_goblin"));
  enemies.add(new Enemy(width / 2 + mapOffsetX + TILE_SIZE * 5, mapOffsetY + TILE_SIZE * 2, "tracker_goblin"));
  enemies.add(new Enemy(width / 2 + mapOffsetX + TILE_SIZE * 14, mapOffsetY + TILE_SIZE * 2, "tracker_goblin"));
  totalEnemiesInLevel = enemies.size();
  
  goldenEggs.add(new Egg(7 * TILE_SIZE + TILE_SIZE/2 + mapOffsetX, 2 * TILE_SIZE + TILE_SIZE/2 + mapOffsetY));
  goldenEggs.add(new Egg(14 * TILE_SIZE + TILE_SIZE/2 + mapOffsetX, 7 * TILE_SIZE + TILE_SIZE/2 + mapOffsetY));
  goldenEggs.add(new Egg(11 * TILE_SIZE + TILE_SIZE/2 + mapOffsetX, 3 * TILE_SIZE + TILE_SIZE/2 + mapOffsetY));
  goldenEggs.add(new Egg(1 * TILE_SIZE + TILE_SIZE/2 + mapOffsetX, 6 * TILE_SIZE + TILE_SIZE/2 + mapOffsetY));
  goldenEggs.add(new Egg(7 * TILE_SIZE + TILE_SIZE/2 + mapOffsetX, 10 * TILE_SIZE + TILE_SIZE/2 + mapOffsetY));
  goldenEggs.add(new Egg(18 * TILE_SIZE + TILE_SIZE/2 + mapOffsetX, 11 * TILE_SIZE + TILE_SIZE/2 + mapOffsetY));
  goldenEggs.add(new Egg(19 * TILE_SIZE + TILE_SIZE/2 + mapOffsetX, 14 * TILE_SIZE + TILE_SIZE/2 + mapOffsetY));
  totalEggs = goldenEggs.size();

  playerGoose.position.set(2 * TILE_SIZE + TILE_SIZE/2 + mapOffsetX, 14 * TILE_SIZE + TILE_SIZE/2 + mapOffsetY);
}
  
// Draw static map elements
void drawLevelMap() {
  rectMode(CENTER);
  for (int r = 0; r < levelMap.length; r++) {
    for (int c = 0; c < levelMap[0].length; c++) {
      if (levelMap[r][c] == 1) { // Draw platform
        float centerX = c * TILE_SIZE + TILE_SIZE / 2 + mapOffsetX;
        float centerY = r * TILE_SIZE + TILE_SIZE / 2 + mapOffsetY;

        fill(100, 70, 30); // Brown for ground
        stroke(0);
        strokeWeight(1);
        rect(centerX, centerY, TILE_SIZE, TILE_SIZE);
        noStroke();
      }
    }
  }
}
  
// Draw background details (non-interactive)
void drawBackgroundDetails() {
  drawCloud(width * 0.1 + mapOffsetX, height * 0.1 + mapOffsetY, 80, 40);
  drawCloud(width * 0.7 + mapOffsetX, height * 0.2 + mapOffsetY, 100, 50);
}

// Simple helper for cloud shapes
void drawCloud(float x, float y, float w, float h) {
  fill(255, 255, 255);
  stroke(0);
  strokeWeight(1);
  ellipse(x, y, w, h); // Main oval
  ellipse(x - w * 0.3, y + h * 0.1, w * 0.7, h * 0.7); // Left lump
  ellipse(x + w * 0.3, y + h * 0.1, w * 0.7, h * 0.7); // Right lump
  ellipse(x, y - h * 0.2, w * 0.5, h * 0.5); // Top lump
}
        
// HUD (Lives, goblins defeated, eggs collected)
void drawHUD() {
  fill(0);
  textSize(18);
  textAlign(LEFT, TOP);
  text("LIVES: " + playerGoose.lives, 10 + mapOffsetX, 10 + mapOffsetY);
  textAlign(RIGHT, TOP);
  text("GOBLINS: " + enemiesDefeated + " / " + totalEnemiesInLevel, width - 10 - mapOffsetX, 10 + mapOffsetY);
  textAlign(CENTER, TOP);
  text("EGGS: " + eggsCollected + " / " + totalEggs, width / 2, 10 + mapOffsetY);
}
  
 
// -------- 5. SCREEN DRAWING FUNCTIONS --------
// Screen renderers for start, game over, and level complete states.

void drawStartScreen() {
  background(102, 0, 102); // Dark grey background
  fill(200, 200, 0); // Vintage yellow text
  textAlign(CENTER);
  textSize(40);
  text("GUBBLE GOBBLE", width / 2, height / 5);
  textSize(28);
  text("ASTON GOOSE ADVENTURE", width / 2, height / 3.5);

  fill(255);
  textSize(18);
  
  // Simple vertical layout for multiline text
  float textY = height / 2.5;
  float lineHeight = 24;
  text("Trouble's brewing - and it's wearing a goblin grin.", width / 2, textY);
  textY += lineHeight;
  text("Trap the grinning menaces in bubbles, then pop them out of existence.", width / 2, textY);
  textY += lineHeight * 2; // spacer
  text("CONTROLS:", width / 2, textY);
  textY += lineHeight;
  text("A / D - Move Left / Right", width / 2, textY);
  textY += lineHeight;
  text("W - Jump", width / 2, textY);
  textY += lineHeight;
  text("Left Ctrl - Shoot a Bubble", width / 2, textY);
  textY += lineHeight * 2; // spacer
  text("Touch trapped goblins to finish them off.", width / 2, textY);
  textY += lineHeight;
  text("Collect all the golden eggs for victory bragging rights.", width / 2, textY);

  fill(0, 200, 0);
  textSize(22);
  text("PRESS ANY KEY TO START!", width / 2, height * 0.9);
}

void drawGameOverScreen() {
  background(80, 0, 0);
  fill(255, 0, 0);
  textAlign(CENTER);
  textSize(48);
  text("GAME OVER!", width / 2, height / 2 - 30);
  fill(255);
  textSize(24);
  text("You bubbled, you popped… you still got dropped.", width / 2, height * 0.7);
  textSize(24);
  text("Press any key to try again.", width / 2, height * 0.7 + 30);
}

void drawGameWonScreen() {
  background(0, 80, 0);
  fill(0, 255, 0);
  textAlign(CENTER);
  textSize(48);
  text("LEVEL CLEARED!", width / 2, height / 2 - 60);
  fill(255);
  text("All Goblins obliterated!", width / 2, height / 2);
  textSize(28);
  text("GOBLINS POPPED: " + enemiesDefeated + " / " + totalEnemiesInLevel, width / 2, height / 2 + 60);
  textSize(24);
  text("PRESS ANY KEY TO PLAY AGAIN!", width / 2, height * 0.85);
}

// -------- 6. INPUT HANDLING --------
// Keyboard controls by game state.

void keyPressed() {
  switch (gameState) {
    case START_SCREEN:
      gameState = PLAYING; // any key starts the game
      break;
    case PLAYING:
    case LEVEL_2:
    case LEVEL_3:
      if (key == 'a' || key == 'A') playerGoose.setMoveDirection(-1); // move left
      else if (key == 'd' || key == 'D') playerGoose.setMoveDirection(1); // move right
      else if (key == 'w' || key == 'W') playerGoose.jump(); // jump
      else if (keyCode == CONTROL) playerGoose.shootBubble(); // shoot
      break;
      
     case GAME_OVER_SCREEN:
       resetGame(); // restart from Level 1
       gameState = PLAYING;
       break;
       
     case GAME_WON_SCREEN:
     // advance levels based on currentLevel
       if (currentLevel == 1) {
       setupLevel2();
       gameState = LEVEL_2;
       } else if (currentLevel == 2) {
         setupLevel3();
         gameState = LEVEL_3;
       } else if (currentLevel == 3) {
         resetGame();
         gameState = START_SCREEN;
       }
       break;
  }
}

void keyReleased() {
  // Stop movement when release matches the active direction
  if (gameState == PLAYING || gameState == LEVEL_2 || gameState == LEVEL_3) {
    if ((key == 'a' || key == 'A') && playerGoose.moveDirection == -1) {
      playerGoose.setMoveDirection(0);
    } else if ((key == 'd' || key == 'D') && playerGoose.moveDirection == 1) {
      playerGoose.setMoveDirection(0);
    }
  }
}

// -------- 7. CLASS DEFINITIONS --------

// ----- GOOSE CLASS -----
// Player character logic: movement, jumping, shooting, collisions, rendering.

class Goose {
  // Core movement & physics
  PVector position;        // Current (x, y)
  PVector velocity;        // Current speed/direction
  PVector acceleration;    // Forces applied (gravity)
  float size = 15;
  float moveSpeed = 3;     
  float jumpForce = -14;   // Negative = upward
  float gravity = 0.4;

  // Status
  int lives;
  boolean onGround = false;
  boolean isInvulnerable = false;
  long invulnerableStartTime = 0;
  final long INVULNERABILITY_DURATION = 1500; // ms

  // Direction & shooting
  int moveDirection = 0;   // -1 left, 0 none, 1 right
  int facingDirection = 1; // 1 right, -1 left
  long lastBubbleShotTime = 0;
  final long BUBBLE_COOLDOWN = 500; // ms
  
  // Constructor
  Goose(float x, float y) {
    position = new PVector(x, y);
    velocity = new PVector(0, 0);
    acceleration = new PVector(0, gravity);
    lives = 3;
  }
    
  // Reset for new game/level
  void reset() {
    position.set(2 * TILE_SIZE + TILE_SIZE/2 + mapOffsetX,
                 14 * TILE_SIZE + TILE_SIZE/2 + mapOffsetY);
    velocity.set(0, 0);
    onGround = false;
    isInvulnerable = false;
    invulnerableStartTime = 0;
    lives = 3;
    moveDirection = 0;
    facingDirection = 1;
    lastBubbleShotTime = 0;
  } 
    
  // Update position, physics, collisions, bounds, invulnerability
  void update() {
    velocity.x = moveDirection * moveSpeed; 
    velocity.add(acceleration); 
    position.add(velocity);

    onGround = false;

    // Platform collisions
    for (Platform p : platforms) {
      if (position.y + size/2 > p.position.y - p.size.y/2 &&
          position.y - size/2 < p.position.y + p.size.y/2 &&
          position.x + size/2 > p.position.x - p.size.x/2 &&
          position.x - size/2 < p.position.x + p.size.x/2) {

        // Land on top
        if (velocity.y > 0 && position.y + size/2 > p.position.y - p.size.y/2) {
          position.y = p.position.y - p.size.y/2 - size/2;
          velocity.y = 0;
          onGround = true;
        }
        // Hit from below
        else if (velocity.y < 0 && position.y + size/2 > p.position.y + p.size.y/2) {
          position.y = p.position.y + p.size.y/2 + size/2;
          velocity.y = 0;
        }
      }
    }
    
    // Horizontal bounds
    if (position.x - size/2 < mapOffsetX) {
      position.x = size/2 + mapOffsetX;
      velocity.x = 0;
    }
    if (position.x + size/2 > width - mapOffsetX) {
      position.x = width - size/2 - mapOffsetX;
      velocity.x = 0;
    }

    // Fall off screen
    if (position.y - size/2 > height - mapOffsetY) {
      takeHit();
      reset();
    }

    // End invulnerability
    if (isInvulnerable && millis() - invulnerableStartTime > INVULNERABILITY_DURATION) {
      isInvulnerable = false;
    }
  }
  
  // Draw Gubble
  void render() {
    pushMatrix();
    translate(position.x, position.y);
    rectMode(CENTER);
    stroke(0);
    strokeWeight(2);

    // Flicker if invulnerable
    if (isInvulnerable && (millis() / 100 % 2 == 0)) {
      popMatrix();
      return;
    }
    
    // Body
    fill(255, 255, 0);
    ellipse(0, 0, size * 1.5, size * 1.2); // body
    rect(-size * 0.3, -size * 0.8, size * 0.6, size * 0.8); // neck
    ellipse(-size * 0.3, -size * 1.3, size * 0.8, size * 0.8); // head

    // Beak
    fill(255, 100, 0);
    triangle(-size * 0.3, -size * 1.5, -size * 0.3, -size * 1.1, -size * 0.6, -size * 1.3);

    // Eye
    fill(0);
    ellipse(-size * 0.45, -size * 1.35, 3, 3);

    // Wings
    fill(200, 200, 0);
    if (!onGround) { 
      float wingFlap = sin(frameCount * 0.3) * 3;
      triangle(-size * 0.8, -size * 0.2 + wingFlap, -size * 0.2, -size * 0.6 + wingFlap, -size * 0.2, size * 0.2 + wingFlap);
      triangle(size * 0.8, -size * 0.2 + wingFlap, size * 0.2, -size * 0.6 + wingFlap, size * 0.2, size * 0.2 + wingFlap);
    } else {
      triangle(-size * 0.8, -size * 0.2, -size * 0.2, -size * 0.6, -size * 0.2, size * 0.2);
      triangle(size * 0.8, -size * 0.2, size * 0.2, -size * 0.6, size * 0.2, size * 0.2);
    }

    // Legs
    fill(255, 100, 0);
    if (onGround && abs(velocity.x) > 0.1) {
      float legSwing = sin(frameCount * 0.2) * 3;
      rect(-size * 0.2, size * 0.5 + legSwing, size * 0.2, size * 0.3);
      rect(size * 0.1, size * 0.5 - legSwing, size * 0.2, size * 0.3);
    } else {
      rect(-size * 0.2, size * 0.5, size * 0.2, size * 0.3);
      rect(size * 0.1, size * 0.5, size * 0.2, size * 0.3);
    }

    popMatrix();
  }
    
  void setMoveDirection(int dir) {
    moveDirection = dir;
    if (dir != 0) facingDirection = dir;
  }

  void jump() {
    if (onGround) {
      velocity.y = jumpForce;
      onGround = false;
    }
  }

  void shootBubble() {
    if (millis() > lastBubbleShotTime + BUBBLE_COOLDOWN) {
      float bubbleX = position.x + facingDirection * (size / 2 + 5);
      float bubbleY = position.y;
      bubbles.add(new Bubble(bubbleX, bubbleY, facingDirection));
      lastBubbleShotTime = millis();
    }
  }

  void takeHit() {
    if (!isInvulnerable) {
      lives--;
      isInvulnerable = true;
      invulnerableStartTime = millis();
    }
  }
}

// --- PLATFORM CLASS ---
// Static platforms for collision checks (drawing handled elsewhere).
class Platform {
  PVector position; // center position
  PVector size;     // width, height

  Platform(float x, float y, float w, float h) {
    position = new PVector(x, y);
    size = new PVector(w, h);
  }

  void render() { /* unused – platforms drawn in drawLevelMap() */ }
}


// --- ENEMY CLASS ---
// Goblins of various types: ground, flying, and tracker variants.
class Enemy {
  PVector position;     // current position
  float size = 20;      // visual size
  float speed = 1.5;    // movement speed
  String type;          // "goblin", "flying_goblin", or "tracker_goblin"
  int moveDirection = 1;   // horizontal direction (-1 left, 1 right)
  int moveDirectionY = 1;  // vertical direction for flying goblins
  boolean isTrapped = false; // true if caught in a bubble

  Enemy(float x, float y, String type) {
    position = new PVector(x, y);
    this.type = type;
    // tracker goblins are slower
    if (type.equals("tracker_goblin")) {
      speed = 1.0;
    } else {
      speed = 2.5;
    }
  }

  // Move and handle AI based on goblin type.
  void update() {
    if (!isTrapped) {
      if (type.equals("flying_goblin")) {
        // patrol horizontally & vertically, bouncing off edges
        position.x += moveDirection * speed;
        position.y += moveDirectionY * speed;

        if (position.x - size / 2 < mapOffsetX) {
          position.x = size / 2 + mapOffsetX;
          moveDirection = 1;
        } else if (position.x + size / 2 > width - mapOffsetX) {
          position.x = width - size / 2 - mapOffsetX;
          moveDirection = -1;
        }
        if (position.y - size / 2 < mapOffsetY) {
          position.y = size / 2 + mapOffsetY;
          moveDirectionY = 1;
        } else if (position.y + size / 2 > height - mapOffsetY) {
          position.y = height - size / 2 - mapOffsetY;
          moveDirectionY = -1;
        }

      } else if (type.equals("tracker_goblin")) {
        // move toward player
        PVector directionToGoose = PVector.sub(playerGoose.position, position);
        directionToGoose.normalize();
        directionToGoose.mult(speed);
        position.add(directionToGoose);

      } else {
        // regular ground patrol
        position.x += moveDirection * speed;

        int currentTileX = floor((position.x - mapOffsetX) / TILE_SIZE);
        int currentTileY = floor((position.y - mapOffsetY) / TILE_SIZE);

        // turn around at edges
        if (moveDirection == 1) {
          if (currentTileX + 1 >= levelMap[0].length || 
              (currentTileY + 1 < levelMap.length && levelMap[currentTileY + 1][currentTileX + 1] == 0)) {
            moveDirection = -1;
          }
        } else {
          if (currentTileX - 1 < 0 || 
              (currentTileY + 1 < levelMap.length && levelMap[currentTileY + 1][currentTileX - 1] == 0)) {
            moveDirection = 1;
          }
        }

        // turn around at walls
        if (moveDirection == 1) {
          if (currentTileX + 1 < levelMap[0].length && levelMap[currentTileY][currentTileX + 1] == 1) {
            moveDirection = -1;
          }
        } else {
          if (currentTileX - 1 >= 0 && levelMap[currentTileY][currentTileX - 1] == 1) {
            moveDirection = 1;
          }
        }
      }
    }
  }

  // Draw enemy with appearance depending on type & trapped state.
  void render() {
    pushMatrix();
    translate(position.x, position.y);
    rectMode(CENTER);
    stroke(0);
    strokeWeight(2);

    // Drawing for both "goblin" and "flying_goblin" types
    if (!isTrapped) {
      if (type.equals("tracker_goblin")) {
        fill(200, 0, 0); // Darker Red for tracker goblin
        // Body (same as regular goblin)
        rect(0, 0, size, size * 1.2);
        // Head (same as regular goblin)
        triangle(0, -size * 0.8, -size * 0.5, -size * 0.2, size * 0.5, -size * 0.2);
        // Eyes (same as regular goblin, but yellow)
        fill(255, 255, 0); // Yellow eyes for tracker
        rect(-size * 0.2, -size * 0.5, 4, 4);
        rect(size * 0.2, -size * 0.5, 4, 4);
        // Mouth (same as regular goblin)
        fill(0);
        rect(0, -size * 0.2, size * 0.6, size * 0.1);
        fill(255); // Teeth
        rect(-size * 0.2, -size * 0.2, 2, 2);
        rect(size * 0.2, -size * 0.2, 2, 2);
        // Small horns (same as regular goblin)
        fill(150, 150, 150);
        triangle(-size * 0.3, -size * 0.8, -size * 0.2, -size * 0.6, -size * 0.1, -size * 0.8);
        triangle(size * 0.3, -size * 0.8, size * 0.2, -size * 0.6, size * 0.1, -size * 0.8);
      } else { // Regular and Flying Goblins
        fill(80, 0, 120); // Darker Purple for scarier goblin
        // Body
        rect(0, 0, size, size * 1.2);
        // Head
        triangle(0, -size * 0.8, -size * 0.5, -size * 0.2, size * 0.5, -size * 0.2);
        // Eyes (slanted)
        fill(255, 0, 0); // Red eyes
        rect(-size * 0.2, -size * 0.5, 4, 4);
        rect(size * 0.2, -size * 0.5, 4, 4);
        // Mouth (jagged)
        fill(0);
        rect(0, -size * 0.2, size * 0.6, size * 0.1);
        fill(255); // Teeth
        rect(-size * 0.2, -size * 0.2, 2, 2);
        rect(size * 0.2, -size * 0.2, 2, 2);
        // Small horns
        fill(150, 150, 150);
        triangle(-size * 0.3, -size * 0.8, -size * 0.2, -size * 0.6, -size * 0.1, -size * 0.8);
        triangle(size * 0.3, -size * 0.8, size * 0.2, -size * 0.6, size * 0.1, -size * 0.8);
      }
    } else {
      // Render trapped state (faded colors)
      if (type.equals("tracker_goblin")) {
        fill(200, 0, 0, 100); // Faded darker red
        // Body
        rect(0, 0, size, size * 1.2);
        // Head
        triangle(0, -size * 0.8, -size * 0.5, -size * 0.2, size * 0.5, -size * 0.2);
        // Eyes
        fill(255, 255, 0, 100);
        rect(-size * 0.2, -size * 0.5, 4, 4);
        rect(size * 0.2, -size * 0.5, 4, 4);
        // Mouth
        fill(0, 100);
        rect(0, -size * 0.2, size * 0.6, size * 0.1);
        fill(255, 100); // Teeth
        rect(-size * 0.2, -size * 0.2, 2, 2);
        rect(size * 0.2, -size * 0.2, 2, 2);
        // Small horns
        fill(150, 150, 150, 100);
        triangle(-size * 0.3, -size * 0.8, -size * 0.2, -size * 0.6, -size * 0.1, -size * 0.8);
        triangle(size * 0.3, -size * 0.8, size * 0.2, -size * 0.6, size * 0.1, -size * 0.8);
      } else {
        fill(80, 0, 120, 100); // Faded darker purple
        // Body
        rect(0, 0, size, size * 1.2);
        // Head
        triangle(0, -size * 0.8, -size * 0.5, -size * 0.2, size * 0.5, -size * 0.2);
        // Eyes
        fill(255, 0, 0, 100);
        rect(-size * 0.2, -size * 0.5, 4, 4);
        rect(size * 0.2, -size * 0.5, 4, 4);
        // Mouth
        fill(0, 100);
        rect(0, -size * 0.2, size * 0.6, size * 0.1);
        fill(255, 100); // Teeth
        rect(-size * 0.2, -size * 0.2, 2, 2);
        rect(size * 0.2, -size * 0.2, 2, 2);
        // Small horns
        fill(150, 150, 150, 100);
        triangle(-size * 0.3, -size * 0.8, -size * 0.2, -size * 0.6, -size * 0.1, -size * 0.8);
        triangle(size * 0.3, -size * 0.8, size * 0.2, -size * 0.6, size * 0.1, -size * 0.8);
      }
      fill(255); // White for text
      textSize(10);
      textAlign(CENTER, BOTTOM);
      text("Zzz", 0, -size * 0.8); // "Zzz" to indicate sleeping/trapped
    }

    popMatrix();
  }

  // Axis-Aligned Bounding Box collision check with goose.
  boolean checkCollision(Goose goose) {
    float gLeft = goose.position.x - goose.size / 2;
    float gRight = goose.position.x + goose.size / 2;
    float gTop = goose.position.y - goose.size / 2;
    float gBottom = goose.position.y + goose.size / 2;

    float eLeft = position.x - size / 2;
    float eRight = position.x + size / 2;
    float eTop = position.y - size / 2;
    float eBottom = position.y + size / 2;

    return (gLeft < eRight && gRight > eLeft &&
            gTop < eBottom && gBottom > eTop); 
  }

  // Put enemy in trapped state.
  void trap() {
    isTrapped = true;
    speed = 0; // Stop moving when trapped
  }
}

// --- BUBBLE CLASS ---
// Projectiles fired by the goose that can trap goblins.
class Bubble {
  PVector position;      // current position
  PVector velocity;      // speed & direction
  float size = 10;       // visual size
  float bubbleSpeed = 5; // movement speed

  // Bubble states
  final int ACTIVE = 0;        // moving, can trap enemies
  final int HIT_WALL = 1;      // hit wall/platform, about to disappear
  final int TRAPPED_ENEMY = 2; // holding an enemy

  int state;                   // current state
  Enemy trappedEnemy = null;   // reference to trapped enemy

  Bubble(float x, float y, int direction) {
    position = new PVector(x, y);
    velocity = new PVector(direction * bubbleSpeed, 0);
    state = ACTIVE;
  }

  // Move bubble and check for collisions or state changes.
  void update() {
    if (state == ACTIVE) {
      position.add(velocity);

      // bounce/stop at map edges
      if (position.x - size / 2 < mapOffsetX || position.x + size / 2 > width - mapOffsetX) {
        state = HIT_WALL;
      }

      // stop on platform collision
      for (Platform p : platforms) {
        if (position.x + size / 2 > p.position.x - p.size.x / 2 &&
            position.x - size / 2 < p.position.x + p.size.x / 2 &&
            position.y + size / 2 > p.position.y - p.size.y / 2 &&
            position.y - size / 2 < p.position.y + p.size.y / 2) {
          state = HIT_WALL;
          break;
        }
      }

    } else if (state == TRAPPED_ENEMY && trappedEnemy != null) {
      // follow enemy position when trapped
      position.set(trappedEnemy.position.x, trappedEnemy.position.y - trappedEnemy.size * 0.5);
    }
  }

  // Draw bubble with visual changes for active/trapped states.
  void render() {
    pushMatrix();
    translate(position.x, position.y);
    rectMode(CENTER);
    stroke(0);
    strokeWeight(1);

    if (state == ACTIVE) {
      fill(100, 150, 255, 150); // blue, semi-transparent
      rect(0, 0, size, size);
    } else if (state == TRAPPED_ENEMY) {
      fill(100, 150, 255, 200); // more opaque
      rect(0, 0, size * 1.5, size * 1.5);
    }

    popMatrix();
  }

  // Axis-Aligned Bounding Box collision check with an enemy.
  boolean checkEnemyHit(Enemy enemy) {
    float bLeft = position.x - size / 2;
    float bRight = position.x + size / 2;
    float bTop = position.y - size / 2;
    float bBottom = position.y + size / 2;

    float eLeft = enemy.position.x - enemy.size / 2;
    float eRight = enemy.position.x + enemy.size / 2;
    float eTop = enemy.position.y - enemy.size / 2;
    float eBottom = enemy.position.y + enemy.size / 2;

    return (bLeft < eRight && bRight > eLeft &&
            bTop < eBottom && bBottom > eTop);
  }
}


// --- EGG CLASS ---
// Collectible golden eggs scattered across the level.
class Egg {
  PVector position; // position on screen
  float size = 15;  // visual size

  Egg(float x, float y) {
    position = new PVector(x, y);
  }

  // Draw the egg with a golden oval shape, texture, and highlight.
  void render() {
    pushMatrix();
    translate(position.x, position.y);
    rectMode(CENTER);
    stroke(0);
    strokeWeight(1);
    fill(255, 200, 0); // golden yellow
    ellipse(0, 0, size, size * 1.4);

    // texture details
    fill(200, 150, 0);
    ellipse(-size * 0.2, size * 0.3, size * 0.3, size * 0.3);
    ellipse(size * 0.1, -size * 0.4, size * 0.3, size * 0.3);

    // highlight
    fill(255, 220, 50);
    ellipse(size * 0.3, -size * 0.5, size * 0.2, size * 0.2);
    popMatrix();
  }

  // Check if the goose is close enough to collect the egg.
  boolean isCollected(Goose goose) {
    float distance = dist(position.x, position.y, goose.position.x, goose.position.y);
    return distance < (size / 2 + goose.size / 2);
  }
}

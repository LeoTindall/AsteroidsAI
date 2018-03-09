class Player implements Comparable {
  PVector pos;
  PVector vel;
  PVector acc;
  
  float INITIAL_FUEL = 300;
  float INITIAL_AMMO = 50;
  float FUEL_PER_FRAME = 0.0;
  float BULLETS_PER_FRAME = 0.0;
  float ACTIVATION_THRESHOLD = 0.8;
  float DECEL_RATIO = 0.995;
  int SHOOT_COUNT_RESET = 60;

  int score = 0;//how many asteroids have been shot
  int shootCount = 0;//stops the player from shooting too quickly
  float rotation;//the ships current rotation
  float spin;//the amount the ship is to spin next update
  float maxSpeed = 10;//limit the players speed at 10
  boolean boosting = false;//whether the booster is on or not
  ArrayList<Bullet> bullets = new ArrayList<Bullet>(); //the bullets currently on screen
  ArrayList<Asteroid> asteroids = new ArrayList<Asteroid>(); // all the asteroids
  int asteroidCount = 1000;//the time until the next asteroid spawns
  int lives = 0;//no lives
  float fuel = INITIAL_FUEL;
  float ammo = INITIAL_AMMO;
  boolean dead = false;//is it dead
  int immortalCount = 0; //when the player looses a life and respawns it is immortal for a small amount of time  
  int boostCount = 10;//makes the booster flash
  
  //--------AI stuff
  NeuralNet brain;
  
  int REACTION_FRAMES = 3;
  
  // VISION_LEN is how much info the nn gets per frame.
  int VISION_LEN = 15;
  int MEMORY = 100;
  
  // DECISION_LEN is how much it puts out - just shoot, left, right, move.
  int DECISION_LEN = 4;
  // Hidden architecture.
  int[] HIDDEN_LAYERS = {20};
  
  
  float[] vision = new float[VISION_LEN];//the input array fed into the neuralNet
  float[][] lastVisions = new float[MEMORY][VISION_LEN]; // the previous input array
  float[] decision = new float[DECISION_LEN]; //the out put of the NN 
  boolean replay = false;//whether the player is being replayed 
  //since asteroids are spawned randomly when replaying the player we need to use a random seed to repeat the same randomness
  long SeedUsed; //the random seed used to intiate the asteroids
  ArrayList<Long> seedsUsed = new ArrayList<Long>();//seeds used for all the spawned asteroids
  int upToSeedNo = 0;//which position in the arrayList 
  float fitness;
  
  String[] decisionDescriptors = {"Boost", "Right", "Left", "Fire"};
  String[] visionDescriptors = {
          "Forward", "Fore Left", "Right", "Rear Right", "Rearward", "Rear Left", "Right", "Fore Right",
          "Can Shoot", "Ammo", "Fuel"};

  // Number of shots fired so far
  int shotsFired = 0;
  // Number of shots hit so far
  int shotsHit = 0;

  int lifespan = 0;//how long the player lived for fitness

  boolean canShoot = true;//whether the player can shoot or not
  //------------------------------------------------------------------------------------------------------------------------------------------
  //constructor
  Player() {
    pos = new PVector(width/2, height/2);
    vel = new PVector();
    acc = new PVector();  
    rotation = 0;
    SeedUsed = floor(random(1000000000)); //create and store a seed
    randomSeed(SeedUsed);

    //generate asteroids
    asteroids.add(new Asteroid(random(width), 0, random(-1, 1), random (-1, 1), 3));
    asteroids.add(new Asteroid(random(width), 0, random(-1, 1), random (-1, 1), 3));
    asteroids.add(new Asteroid(0, random(height), random(-1, 1), random (-1, 1), 3));
    asteroids.add(new Asteroid(random(width), random(height), random(-1, 1), random (-1, 1), 3));
    //aim the fifth one at the player
    float randX = random(width);
    float randY = -50 +floor(random(2))* (height+100);
    asteroids.add(new Asteroid(randX, randY, pos.x- randX, pos.y - randY, 3));     
    brain = new NeuralNet(VISION_LEN * (MEMORY + 1), HIDDEN_LAYERS, DECISION_LEN); // Hidden layers are input + output
  }
  //------------------------------------------------------------------------------------------------------------------------------------------
  //constructor used for replaying players
  Player(long seed) {
    replay = true;//is replaying
    pos = new PVector(width/2, height/2);
    vel = new PVector();
    acc = new PVector();
    rotation = 0;
    SeedUsed = seed;//use the parameter seed to set the asteroids at the same position as the last one
    randomSeed(SeedUsed);
    //generate asteroids
    asteroids.add(new Asteroid(random(width), 0, random(-1, 1), random (-1, 1), 3));
    asteroids.add(new Asteroid(random(width), 0, random(-1, 1), random (-1, 1), 3));
    asteroids.add(new Asteroid(0, random(height), random(-1, 1), random (-1, 1), 3));
    asteroids.add(new Asteroid(random(width), random(height), random(-1, 1), random (-1, 1), 3));
    //aim the fifth one at the player
    float randX = random(width);
    float randY = -50 +floor(random(2))* (height+100);
    asteroids.add(new Asteroid(randX, randY, pos.x- randX, pos.y - randY, 3));
  }

  //------------------------------------------------------------------------------------------------------------------------------------------
  //Move player
  void move() {
    if (!dead) {
      checkTimers();
      rotatePlayer();
      if (boosting) {//are thrusters on
        boost();
      } else {
        boostOff();
      }

      vel.add(acc);//velocity += acceleration
      vel.limit(maxSpeed);
      vel.mult(DECEL_RATIO); // uncomment to enable decelleration.
      pos.add(vel);//position += velocity

      for (int i = 0; i < bullets.size(); i++) {//move all the bullets
        bullets.get(i).move();
      }

      for (int i = 0; i < asteroids.size(); i++) {//move all the asteroids
        asteroids.get(i).move();
      }
      if (isOut(pos)) {//wrap the player around the gaming area
        loopy();
      }
    }
  }
  //------------------------------------------------------------------------------------------------------------------------------------------
  //move through time and check if anything should happen at this instance
  void checkTimers() {
    lifespan +=1;
    shootCount --;
    asteroidCount--;
    if (asteroidCount<=0) {//spawn asteorid

      if (replay) {//if replaying use the seeds from the arrayList
        upToSeedNo ++;
      } else {//if not generate the seeds and then save them
        long seed = floor(random(1000000));
        seedsUsed.add(seed);
        randomSeed(seed);
      }
      //aim the asteroid at the player to encourage movement
      float randX = random(width);
      float randY = -50 +floor(random(2))* (height+100);
      asteroids.add(new Asteroid(randX, randY, pos.x- randX, pos.y - randY, 3));
      asteroidCount = 1000;
    }
    
    if (shootCount <=0) {
      canShoot = true;
    }
  }



  //------------------------------------------------------------------------------------------------------------------------------------------
  //booster
  void boost() {
    acc = PVector.fromAngle(rotation);
    if (fuel >= 1) {
      acc.setMag(0.1);
      fuel -= 0.1;
    } else {
      boostOff();
    }
  }

  //------------------------------------------------------------------------------------------------------------------------------------------
  //boostless
  void boostOff() {
    acc.setMag(0);
  }
  //------------------------------------------------------------------------------------------------------------------------------------------
  //spin that player
  void rotatePlayer() {
    rotation += spin;
  }
  //------------------------------------------------------------------------------------------------------------------------------------------
  //draw the player, bullets and asteroids 
  void show() {
    if (!dead) {
      for (int i = 0; i < bullets.size(); i++) {//show bullets
        bullets.get(i).show();
      }
      if (immortalCount >0) {//no need to decrease immortalCOunt if its already 0
        immortalCount --;
      }
      if (immortalCount >0 && floor(((float)immortalCount)/5)%2 ==0) {//needs to appear to be flashing so only show half of the time
      } else {
        pushMatrix();
        translate(pos.x, pos.y);
        rotate(rotation);
        //actually draw the player
        fill(0);
        noStroke();
        beginShape();
        int size = 12;
        //black triangle
        vertex(-size-2, -size);
        vertex(-size-2, size);
        vertex(2* size -2, 0);
        endShape(CLOSE);
        stroke(255);
        //white out lines
        line(-size-2, -size, -size-2, size);
        line(2* size -2, 0, -22, 15);
        line(2* size -2, 0, -22, -15);
        if (boosting && fuel >= 1) {//when boosting draw "flames" its just a little triangle
          boostCount --;
          if (floor(((float)boostCount)/3)%2 ==0) {//only show it half of the time to appear like its flashing
            line(-size-2, 6, -size-2-12, 0);
            line(-size-2, -6, -size-2-12, 0);
          }
        }
        popMatrix();
        
        // Draw the fuel and ammo counts
        textAlign(LEFT);
        textFont(smallFont);
        fill(256, 256, 0);
        text("F" + nf(fuel, 4, 1), 10, height - 20);
        fill(0, 0, 256);
        text("A" + nf(ammo, 4, 1), 10, height - 40);
        
        // Draw decision counts/inputs
        textAlign(RIGHT);
        textFont(smallFont);
        int textY = height - 40;
        for (int j = 0; j < decisionDescriptors.length; j++) {
          if (decision[j] > ACTIVATION_THRESHOLD) {
            fill(0, 256, 0);
          } else {
            fill(256, 0, 0);
          }
          textY -= 20;
          text(decisionDescriptors[j] + ": " + nf(decision[j], 1, 6), width - 10, textY);
        }
        
        for (int j = 0; j < visionDescriptors.length; j++) {
          int yellow = int(256.0 * vision[j]);
          int blue = int(256.0 * (1.0 - vision[j]));
          fill(yellow, yellow, blue);
          textY -= 20;
          //text(nf(vision[j], 1, 6), width-10, textY);
          text(visionDescriptors[j], width-10, textY);
        }
      }
    }
    for (int i = 0; i < asteroids.size(); i++) {//show asteroids
      asteroids.get(i).show();
    }
  }
  //------------------------------------------------------------------------------------------------------------------------------------------
  //shoot a bullet
  void shoot() {
    if (shootCount <=0 && ammo >= 1) {//if can shoot
      bullets.add(new Bullet(pos.x, pos.y, rotation, vel.mag()));//create bullet
      shootCount = SHOOT_COUNT_RESET;//reset shoot count
      canShoot = false;
      shotsFired ++;
      ammo --;
    }
  }
  //------------------------------------------------------------------------------------------------------------------------------------------
  //in charge or moving everything and also checking if anything has been shot or hit 
  void update() {
    for (int i = 0; i < bullets.size(); i++) {//if any bullets expires remove it
      if (bullets.get(i).off) {
        bullets.remove(i);
        i--;
      }
    }
    // recharge fuel
    fuel += FUEL_PER_FRAME;
    ammo += BULLETS_PER_FRAME;
    move();//move everything
    checkPositions();//check if anything has been shot or hit
  }
  //------------------------------------------------------------------------------------------------------------------------------------------
  //check if anything has been shot or hit
  void checkPositions() {
    //check if any bullets have hit any asteroids
    for (int i = 0; i < bullets.size(); i++) {
      for (int j = 0; j < asteroids.size(); j++) {
        if (asteroids.get(j).checkIfHit(bullets.get(i).pos)) {
          shotsHit ++;
          bullets.remove(i);//remove bullet
          score +=1;
          break;
        }
      }
    }
    //check if player has been hit
    if (immortalCount <=0) {
      for (int j = 0; j < asteroids.size(); j++) {
        if (asteroids.get(j).checkIfHitPlayer(pos)) {
          playerHit();
        }
      }
    }
  }
  //------------------------------------------------------------------------------------------------------------------------------------------
  //called when player is hit by an asteroid
  void playerHit() {
    if (lives == 0) {//if no lives left
      dead = true;
    } else {//remove a life and reset positions
      lives -=1;
      immortalCount = 100;
      resetPositions();
    }
  }
  //------------------------------------------------------------------------------------------------------------------------------------------
  //returns player to center
  void resetPositions() {
    pos = new PVector(width/2, height/2);
    vel = new PVector();
    acc = new PVector();  
    bullets = new ArrayList<Bullet>();
    rotation = 0;
  }
  //------------------------------------------------------------------------------------------------------------------------------------------
  //wraps the player around the playing area
  void loopy() {
    if (pos.y < -50) {
      pos.y = height + 50;
    } else
      if (pos.y > height + 50) {
        pos.y = -50;
      }
    if (pos.x< -50) {
      pos.x = width +50;
    } else  if (pos.x > width + 50) {
      pos.x = -50;
    }
  }

  //---------------------------------------------------------------------------------------------------------------------------------------------------------<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  //for genetic algorithm
  float calculateFitness() {
    fitness = 0;
    /*float hitRate = (float)shotsHit/(float)shotsFired;
    if (hitRate == hitRate) { // if hitRate is NaN then ignore it
      fitness += lifespan * score * hitRate * hitRate;//includes hitrate to encourage aiming
    }
    fitness += lifespan * score; // lifespan and score are the main thing here*/
    fitness += lifespan / 10; // If nothing else fall back to lifespan
    
    return fitness;
    
  }

  //---------------------------------------------------------------------------------------------------------------------------------------------------------  
  void mutate() {
    brain.mutate(globalMutationRate);
  }
  //---------------------------------------------------------------------------------------------------------------------------------------------------------  
  //returns a clone of this player with the same brian
  Player clone() {
    Player clone = new Player();
    clone.brain = brain.clone();
    return clone;
  }
  //returns a clone of this player with the same brian and same random seeds used so all of the asteroids will be in  the same positions
  Player cloneForReplay() {
    Player clone = new Player(SeedUsed);
    clone.brain = brain.clone();
    clone.seedsUsed = (ArrayList)seedsUsed.clone();
    return clone;
  }

  //---------------------------------------------------------------------------------------------------------------------------------------------------------  
  Player crossover(Player parent2) {
    Player child = new Player();
    child.brain = brain.crossover(parent2.brain);
    return child;
  }
  //---------------------------------------------------------------------------------------------------------------------------------------------------------  

  //looks in 8 directions to find asteroids
  //also takes into account ability to shoot, ammo, and fuel
  void look() {
    if (frameCount % REACTION_FRAMES != 0) {
      return;
    }
    // Roll the buffer
    for (int i = MEMORY-1; i > 0; i--) {
      lastVisions[i] = lastVisions[i-1];
    }
    
    // Look around
    vision = new float[VISION_LEN];
    //look left
    PVector direction;
    for (int i = 0; i< vision.length; i++) {
      direction = PVector.fromAngle(rotation + i*(PI/4));
      direction.mult(10);
      vision[i] = lookInDirection(direction);
    }

    if (canShoot) {
      vision[8] = 1;
    } else {
      vision[8] =0;
    }
    
    vision[9] = constrain(ammo / INITIAL_AMMO, 0, 1);
    vision[10] = constrain(fuel / INITIAL_FUEL, 0, 1);
  }
  //---------------------------------------------------------------------------------------------------------------------------------------------------------  


  float lookInDirection(PVector direction) {
    //set up a temp array to hold the values that are going to be passed to the main vision array

    PVector position = new PVector(pos.x, pos.y);//the position where we are currently looking
    float distance = 0;
    //move once in the desired direction before starting 
    position.add(direction);
    distance +=1;

    //look in the direction until you reach a wall
    while (distance< 60) {//!(position.x < 400 || position.y < 0 || position.x >= 800 || position.y >= 400)) {


      for (Asteroid a : asteroids) {
        if (a.lookForHit(position) ) {
          return (60 - distance) / 60;
        }
      }

      //look further in the direction
      position.add(direction);

      //loop it
      if (position.y < -50) {
        position.y += height + 100;
      } else
        if (position.y > height + 50) {
          position.y -= height -100;
        }
      if (position.x< -50) {
        position.x += width +100;
      } else  if (position.x > width + 50) {
        position.x -= width +100;
      }
      distance +=1;
    }
    return 0;
  }
  //---------------------------------------------------------------------------------------------------------------------------------------------------------  

  //saves the player to a file by converting it to a table
  void savePlayer(int playerNo, int score, int popID) {
    //save the players top score and its population id 
    Table playerStats = new Table();
    playerStats.addColumn("Top Score");
    playerStats.addColumn("PopulationID");
    TableRow tr = playerStats.addRow();
    tr.setFloat(0, score);
    tr.setInt(1, popID);

    saveTable(playerStats, "data/playerStats" + playerNo+ ".csv");

    //save players brain
    //saveTable(brain.NetToTable(), "data/player" + playerNo+ ".csv");
  }
  //---------------------------------------------------------------------------------------------------------------------------------------------------------  

  //return the player saved in the parameter posiition
  Player loadPlayer(int playerNo) {

    Player load = new Player();
    Table t = loadTable("data/player" + playerNo + ".csv");
    //load.brain.TableToNet(t);
    return load;
  }

  //---------------------------------------------------------------------------------------------------------------------------------------------------------      
  //convert the output of the neural network to actions
  void think() {
    // Fuse all inputs of the network
    float[] input = new float[VISION_LEN * (MEMORY + 1)];
    for (int i = 0; i < vision.length; i++) {
      input[i] = vision[i];
      for (int j = 0; j < MEMORY; j++) {
        input[i + (VISION_LEN*(j+1)) - 1] = lastVisions[j][i];
      }
    }
    decision = brain.output(input);
    
    boolean doBoost = decision[0] > ACTIVATION_THRESHOLD;
    float spinMagnitude = norm(decision[1], 0, ACTIVATION_THRESHOLD) * 0.08;
    float spinInverseMagnitude = norm(decision[2], 0, ACTIVATION_THRESHOLD) * 0.08;
    //boolean doSpinLeft = decision[1] > ACTIVATION_THRESHOLD;
    //boolean doSpinRight = decision[2] > ACTIVATION_THRESHOLD;
    boolean doShoot = decision[3] > ACTIVATION_THRESHOLD;

    // Try to boost!
    boosting = doBoost;
    
    spin = spinMagnitude - spinInverseMagnitude;

    //shooting
    if (doShoot) {
      shoot();
    }
  }
  
  int compareTo(Object o) {
    Player p = (Player) o;
    return new Float(calculateFitness()).compareTo(p.calculateFitness());
  }
}
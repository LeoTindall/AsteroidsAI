class Player {
  PVector pos;
  PVector vel;
  PVector acc;
  
  int INITIAL_FUEL = 500;
  int INITIAL_AMMO = 45;
  float ACTIVATION_THRESHOLD = 0.82;

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
  int fuel = INITIAL_FUEL;
  int ammo = INITIAL_AMMO;
  boolean dead = false;//is it dead
  int immortalCount = 0; //when the player looses a life and respawns it is immortal for a small amount of time  
  int boostCount = 10;//makes the booster flash
  //--------AI stuff
  NeuralNet brain;
  float[] vision = new float[15];//the input array fed into the neuralNet
  float[] lastVision = new float[15]; // the previous input array
  float[] last2Vision = new float[15]; // the previous input array
  float[] last3Vision = new float[15]; // the previous input array
  float[] decision = new float[8]; //the out put of the NN 
  boolean replay = false;//whether the player is being raplayed 
  //since asteroids are spawned randomly when replaying the player we need to use a random seed to repeat the same randomness
  long SeedUsed; //the random seed used to intiate the asteroids
  ArrayList<Long> seedsUsed = new ArrayList<Long>();//seeds used for all the spawned asteroids
  int upToSeedNo = 0;//which position in the arrayList 
  float fitness;
  
  String[] decisionDescriptors = {"Boost", "Left", "Right", "Fire"};
  String[] visionDescriptors = {
          "Forward", "Foreleft", "Left", "Rearleft", "Rearward", "Rearright", "Right", "Foreright",
          "Can Shoot", "Ammo", "Fuel"};
  String[] rnnDescriptors = {"Logistic Memory", "Quadratic Memory", "Linear Memory 1", "Linear Memory 2"};

  int shotsFired =4;//initiated at 4 to encourage shooting
  int shotsHit = 1; //initiated at 1 so players dont get a fitness of 1

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
    brain = new NeuralNet(60, 48, 8); // Hidden layers are 2/3 * input + output 
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
      //vel.mult(0.99); // uncomment to enable decelleration. I prefer not to have that.
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
        randomSeed(seedsUsed.get(upToSeedNo));
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
    if (fuel > 0) {
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
        if (boosting && fuel > 0) {//when boosting draw "flames" its just a little triangle
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
        text("F" + nf(fuel, 6), 10, height - 20);
        fill(0, 0, 256);
        text("A" + nf(ammo, 6), 10, height - 40);
        
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
        
        for (int j = visionDescriptors.length; j < lastVision.length; j++) {
          int yellow = int(256.0 * lastVision[j]);
          int blue = int(256.0 * (1.0 - lastVision[j]));
          fill(yellow, yellow, blue);
          textY -= 20;
          //text(nf(vision[j], 1, 6), width-10, textY);
          text(rnnDescriptors[j - visionDescriptors.length], width-10, textY);
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
    if (shootCount <=0 && ammo > 0) {//if can shoot
      bullets.add(new Bullet(pos.x, pos.y, rotation, vel.mag()));//create bullet
      shootCount = 30;//reset shoot count
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
  void calculateFitness() {
    float hitRate = (float)shotsHit/(float)shotsFired;
    fitness = (score+1) * 100;
    fitness *= lifespan;
    fitness *= hitRate*hitRate;//includes hitrate to encourage aiming
    
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
    // Roll the buffer
    last3Vision = last2Vision;
    last2Vision = lastVision;
    lastVision = vision;
    
    // Process recursion.
    lastVision[11] = constrain(log(decision[4]), 0, 1);
    lastVision[12] = constrain(decision[5] * decision[5], 0, 1);
    lastVision[13] = constrain(decision[6], 0, 1);
    lastVision[14] = constrain(decision[7], 0, 1);
    vision = new float[15];
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
    
    vision[9] = float(ammo) / INITIAL_AMMO;
    vision[10] = float(fuel) / INITIAL_FUEL;
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
          return 1/log(distance);
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
    saveTable(brain.NetToTable(), "data/player" + playerNo+ ".csv");
  }
  //---------------------------------------------------------------------------------------------------------------------------------------------------------  

  //return the player saved in the parameter posiition
  Player loadPlayer(int playerNo) {

    Player load = new Player();
    Table t = loadTable("data/player" + playerNo + ".csv");
    load.brain.TableToNet(t);
    return load;
  }

  //---------------------------------------------------------------------------------------------------------------------------------------------------------      
  //convert the output of the neural network to actions
  void think() {
    //get the output of the neural network
    float[] input = new float[vision.length * 4];
    for (int i = 0; i < vision.length; i++) {
      input[i] = vision[i];
      input[i+11] = lastVision[i];
      input[i+22] = last2Vision[i];
      input[i+33] = last3Vision[1];
    }
    decision = brain.output(input);

    if (decision[0] > ACTIVATION_THRESHOLD) {//output 0 is boosting
      boosting = true;
    } else {
      boosting = false;
    }
    if (decision[1] > ACTIVATION_THRESHOLD && decision[2] < ACTIVATION_THRESHOLD) {//output 1 is turn left
      spin = -0.08;
    } else if (decision[2] > ACTIVATION_THRESHOLD && decision[1] < ACTIVATION_THRESHOLD) {//output 2 is turn right
        spin = 0.08;
    } else {//if neither or indicisive
        spin = 0;
    }
    //shooting
    if (decision[3] > ACTIVATION_THRESHOLD) {//output 3 is shooting
      shoot();
    }
  }
}
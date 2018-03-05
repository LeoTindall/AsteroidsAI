Player humanPlayer;//the player which the user (you) controls
Population pop;
int speed = 512;
int POP_SIZE = 200; // 414 is the most that fits on the screen
int currentInView = 0;
float globalMutationRate = 0.1;
PFont font;
PFont smallFont;
PFont tinyFont;
//boolean Values 
boolean showBest = false;//true if show a ship playing
boolean runBest = false; //true if replaying the best ever game
boolean humanPlaying = false; //true if the user is playing
void setup() {//on startup
  size(1200, 675);

  humanPlayer = new Player();
  pop = new Population(POP_SIZE);// create new population of size 200
  frameRate(speed);
  font = loadFont("LiberationSans-48.vlw");
  smallFont = loadFont("LiberationSans-24.vlw");
  tinyFont = loadFont("LiberationSans-12.vlw");
}
//------------------------------------------------------------------------------------------------------------------------------------------

void draw() {
  background(0); //deep space background
  if (humanPlaying) {//if the user is controling the ship[
    if (!humanPlayer.dead) {//if the player isnt dead then move and show the player based on input
      humanPlayer.update();
      humanPlayer.show();
    } else {//once done return to ai
      humanPlaying = false;
    }
  } else if (runBest) {// if replaying the best ever game
    if (pop.bestPlayer == null) { // Can't do that if there's no best
      runBest = false;
    } else {
      if (!pop.bestPlayer.dead) {//if best player is not dead
        pop.bestPlayer.look();
        pop.bestPlayer.think();
        pop.bestPlayer.update();
        pop.bestPlayer.show();
      } else {//once dead
        runBest = false;//stop replaying it
        pop.bestPlayer = pop.bestPlayer.cloneForReplay();//reset the best player so it can play again
      }
  }
  } else {//if just evolving normally
    if (!pop.done()) {//if any players are alive then update them
      if (showBest) {
        // Show the selected player
        pop.updateAlive(currentInView);
      } else {
        // Show no player, but still update
        pop.updateAlive(-1);
        pop.showStatus();
        showScore();
      }
    } else {//all dead
      //genetic algorithm 
      pop.calculateFitness(); 
      pop.naturalSelection();
    }
  }
  showScore();//display the score
}
//------------------------------------------------------------------------------------------------------------------------------------------

void keyPressed() {
  switch(key) {
  case ' ':
    if (humanPlaying) {//if the user is controlling a ship shoot
      humanPlayer.shoot();
    } else {//if not toggle showBest
      showBest = !showBest;
    }
    break;
  case 'p'://play
    humanPlaying = !humanPlaying;
    humanPlayer = new Player();
    break;  
  case '+'://speed up frame rate
    speed += 10;
    frameRate(speed);
    println(speed);

    break;
  case '-'://slow down frame rate
    if (speed > 10) {
      speed -= 10;
      frameRate(speed);
      println(speed);
    }
    break;
  case 'h'://halve the mutation rate
    globalMutationRate /=2;
    println(globalMutationRate);
    break;
  case 'd'://double the mutation rate
    globalMutationRate *= 2;
    println(globalMutationRate);
    break;
  case 'b'://run the best
    runBest = true;
    break;
  }
  
  //player controls
  if (key == CODED) {
    if (keyCode == UP) {
      humanPlayer.boosting = true;
    }
    if (keyCode == LEFT) {
      if (humanPlaying) {
        humanPlayer.spin = -0.08;
      } else {
        do {
          currentInView = (currentInView - 1) % POP_SIZE;
          if (currentInView < 0) {
            currentInView = POP_SIZE - 1;
          }
        } while (pop.players[currentInView].dead);
      }
    } else if (keyCode == RIGHT) {
      if (humanPlaying) {
        humanPlayer.spin = 0.08;
      } else {
        do {
          currentInView = (currentInView + 1) % POP_SIZE;
        } while (pop.players[currentInView].dead);
      }
    }
  }
}

void keyReleased() {
  //once key released
  if (key == CODED) {
    if (keyCode == UP) {//stop boosting
      humanPlayer.boosting = false;
    }
    if (keyCode == LEFT) {// stop turning
      humanPlayer.spin = 0;
    } else if (keyCode == RIGHT) {
      humanPlayer.spin = 0;
    }
  }
}

//------------------------------------------------------------------------------------------------------------------------------------------
//function which returns whether a vector is out of the play area
boolean isOut(PVector pos) {
  if (pos.x < -50 || pos.y < -50 || pos.x > width+ 50 || pos.y > 50+height) {
    return true;
  }
  return false;
}

//------------------------------------------------------------------------------------------------------------------------------------------
//shows the score and the generation on the screen
void showScore() {
  if (humanPlaying) {
    textFont(font);
    fill(255);
    textAlign(LEFT);
    text("Score: " + humanPlayer.score, 80, 60);
  } else
    if (runBest) {
      textFont(font);
      fill(255);
      textAlign(LEFT);
      text("Score: " + pop.bestPlayer.score, 80, 60);
      text("Gen: " + pop.gen, width-200, 60);
    } else {
      if (showBest) {
        textFont(font);
        fill(255);
        textAlign(LEFT);
        text("Score: " + pop.players[currentInView].score, 80, 60);
        text("Gen: " + pop.gen + " Ind: " + currentInView, width-500, 60);
      } else {
        // For the status indicator
        textFont(font);
        fill(255);
        textAlign(LEFT);
        text("Player Status ", 80, 60);
        text("Gen: " + pop.gen, width-300, 60);
      }
    }
  
  // Show the current state
  textFont(smallFont);
  fill(128);
  textAlign(CENTER);
  int statusX = width/2;
  int statusY = height - 20;
  if (humanPlaying) {
    text("Human Playing. SPACEBAR fired weapon, left and right rotate, up fires booster.", statusX, statusY);
  } else if (showBest) {
    text("Computer Playing. Left and right cycle through living individuals; SPACEBAR to view status.", statusX, statusY);
  } else if (runBest) {
    text("Replay. b exits.", statusX, statusY);
  } else {
    text("SPACEBAR to exit status mode. d/h double and halve mutation rate: " + globalMutationRate, statusX, statusY);
  }
  text("Target FPS (+ and -): " + speed + ", Actual FPS: " + nf(int(frameRate), 3), statusX, statusY - 20);
}
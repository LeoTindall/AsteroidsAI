// Configuration values
int POP_SIZE = 256  ; // 414 is the most that fits on the screen
int INITIAL_SPEED = 256;
float INITIAL_MUTATION_RATE = 0.1;

// State values
Population pop;
int speed = INITIAL_SPEED;
int currentInView = 0;
float globalMutationRate = INITIAL_MUTATION_RATE;
PFont font;
PFont smallFont;
PFont tinyFont;

//boolean Values 
boolean showPlaying = false;//true if show a ship playing
boolean replayBest = false; //true if replaying the best ever game

void setup() {//on startup
  size(1200, 675);

  pop = new Population(POP_SIZE);
  frameRate(speed);
  font = loadFont("LiberationSans-48.vlw");
  smallFont = loadFont("LiberationSans-24.vlw");
  tinyFont = loadFont("LiberationSans-12.vlw");
}
//------------------------------------------------------------------------------------------------------------------------------------------

void draw() {
  background(0); //deep space background
  if (replayBest) {// if replaying the best ever game
    if (pop.bestPlayer == null) { // Can't do that if there's no best
      replayBest = false;
    } else {
      if (!pop.bestPlayer.dead) {//if best player is not dead
        pop.bestPlayer.look();
        pop.bestPlayer.think();
        pop.bestPlayer.update();
        pop.bestPlayer.show();
      } else {//once dead
        replayBest = false;//stop replaying it
        pop.bestPlayer = pop.bestPlayer.cloneForReplay();//reset the best player so it can play again
      }
  }
  } else {//if just evolving normally
    if (!pop.done()) {//if any players are alive then update them
      if (showPlaying) {
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
      // Toggle between playing and scoreboard
      showPlaying = !showPlaying;
    break;
  case '+'://speed up frame rate
    speed += 10;
    frameRate(speed);
    break;
  case '-'://slow down frame rate
    if (speed > 10) {
      speed -= 10;
      frameRate(speed);
    }
    break;
  case 'h'://halve the mutation rate
    globalMutationRate /=2;
    break;
  case 'd'://double the mutation rate
    globalMutationRate *= 2;
    break;
  case 'b':
    // Toggle re-playing the best ever
    replayBest = !replayBest;
    break;
  }
  
  // Move through possible views.
  if (key == CODED) {
    if (keyCode == LEFT) {
      int lastInView = currentInView;
      do {
        currentInView = (currentInView - 1) % POP_SIZE;
        if (currentInView < 0) {
          currentInView = POP_SIZE - 1;
        }
      } while (pop.players[currentInView].dead && currentInView != lastInView);
    } else if (keyCode == RIGHT) {
      int lastInView = currentInView;
      do {
        currentInView = (currentInView + 1) % POP_SIZE;
      } while (pop.players[currentInView].dead && currentInView != lastInView);
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
  // If replaying the best ever game, display info about it.
  if (replayBest) {
    textFont(font);
    fill(255);
    textAlign(LEFT);
    text("Score: " + pop.bestPlayer.score, 80, 60);
    text("Gen: " + pop.gen, width-200, 60);
  } else if (showPlaying) {
    textFont(font);
    fill(255);
    textAlign(LEFT);
    text("Score: " + pop.players[currentInView].score, 80, 60);
    text("Gen: " + pop.gen + " Ind: " + currentInView, width-500, 60);
    
    if (frameCount % 10 == 0) {
      pop.players[currentInView].calculateFitness();
    }
    // Show fitness
    textFont(tinyFont);
    text("Fitness: " + pop.players[currentInView].fitness, 80, 70);
  } else {
    // For the status indicator
    textFont(font);
    fill(255);
    textAlign(LEFT);
    text("Player Status ", 80, 60);
    text("Gen: " + pop.gen, width-300, 60);
  }
  
  // Show the current state
  textFont(smallFont);
  fill(128);
  textAlign(CENTER);
  int statusX = width/2;
  int statusY = height - 20;
  if (showPlaying) {
    text("Computer Playing. Left and right cycle through living individuals; SPACEBAR to view status.", statusX, statusY);
  } else if (replayBest) {
    text("Replay of best fit so far. b exits.", statusX, statusY);
  } else {
    text("SPACEBAR to exit status mode. d/h double and halve mutation rate: " + globalMutationRate, statusX, statusY);
  }
  text("Target FPS (+ and -): " + speed + ", Actual FPS: " + nf(int(frameRate), 3), statusX, statusY - 20);
}
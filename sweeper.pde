/* @pjs font="FORCED-SQUARE.ttf"; */

/*
 * sweeper
 * Deniz Basegmez
 * 1/29/15
 *
 * a simple minesweeper clone
 *
 * [left click]         reveal cell
 * [right click]        flag cell
 * [shift + left click
 * OR middle click]     chord
 */

Board board;

// game options
final int GRIDWIDTH  = 20; // width of board
final int GRIDHEIGHT = 14; // height of board
final int MINECOUNT  = 35; // number of mines to place

// graphics options
final boolean ALTIMAGES = true; // enable alternative images?
final boolean ENABLEFX  = true; // enable ripple effect?
final int RIPPLEAMP     = 10;   // ripple effect amplitude

// game states
final int NEWGAME  = 0;
final int RUNNING  = 1;
final int GAMELOST = 2;
final int GAMEWON  = 3;

// pixel dimensions of cells
// 32px default
// 24px alternative
final int CELLSIZE = !ALTIMAGES ? 32 : 24;

// array of colors to color number of adjacent cells text based on number
final color[] COLORS = {color(0   , 0   , 255),  // blue
                        color(0   , 200 , 0  ),  // green
                        color(255 , 0   , 0  ),  // red
                        color(0   , 0   , 150),  // dark blue
                        color(165 , 40  , 40 ),  // brown
                        color(0   , 255 , 255),  // cyan
                        color(0   , 0   , 0  ),  // black
                        color(75  , 75  , 75 )}; // gray

// array of direction differences for finding 8 adjacent cells
final int[][] DIRECTIONS = {{-1 , -1 }, {-1 , 0 }, {-1 , 1 },
                            { 0 , -1 },            { 0 , 1 },
                            { 1 , -1 }, { 1 , 0 }, { 1 , 1 }};

// external resources
PImage imgNormal, imgRevealed, imgMine, imgFlag;
PFont font;

void setup() {

  // set window size to fit board
  size(CELLSIZE * GRIDWIDTH, CELLSIZE * GRIDHEIGHT);

  // initialize board
  board = new Board(GRIDWIDTH, GRIDHEIGHT, MINECOUNT, ENABLEFX, RIPPLEAMP);

  // load images
  imgNormal   = loadImage(!ALTIMAGES ? "cell.png"      : "cell_alt.png");
  imgRevealed = loadImage(!ALTIMAGES ? "cell_down.png" : "cell_down_alt.png");
  imgMine     = loadImage(!ALTIMAGES ? "mine.png"      : "mine_alt.png");
  imgFlag     = loadImage(!ALTIMAGES ? "flag.png"      : "flag_alt.png");

  // processing.js font compatibility
  if (online) {
    font = createFont("FORCED-SQUARE", 20);
  } else {
    font = loadFont("FORCED-SQUARE-20.vlw");
  }

  // set drawing options
  textAlign(CENTER, CENTER);
  textFont(font, 20);
  noStroke();
}

void draw() {
  board.drawBoard();
}

void mouseClicked() {
  board.hookMouse();
}

// used in Board, contains all information about a specific cell on the board
class Cell {
  boolean mine     = false; // is the cell a mine?
  boolean revealed = false; // is the cell revealed?
  boolean flagged  = false; // is the cell flagged?
  int row, col;             // position on board
  int adjMines = 0;         // number of adjacent mines

  Cell(int _row, int _col) {
    this.row = _row;
    this.col = _col;
  }

  boolean isRevealed() {
    return revealed;
  }

  boolean isFlagged() {
    return flagged;
  }

  boolean isMine() {
    return mine;
  }

  int getAdjMines() {
    return adjMines;
  }

  int getRow() {
    return row;
  }

  int getCol() {
    return col;
  }

  void toggleFlagged() {
    flagged = !flagged;
  }

  void setRevealed() {
    revealed = true;
  }

  void setMine() {
    mine = true;
  }

  void setAdjMines(int n) {
    adjMines = n;
  }

  void reset() {
    mine     = false;
    revealed = false;
    flagged  = false;
    adjMines = 0;
  }

  // draws the cell on screen
  void drawCell(boolean showMines) {
    pushMatrix();
    translate(col * CELLSIZE, row * CELLSIZE);

    // draw inset tile if revealed
    if (revealed) {
      image(imgRevealed, 0, 0);

      // print number of mines in middle of non-zero cells
      if (adjMines > 0) {

        // set color based on number of mines
        fill(COLORS[adjMines - 1]);
        text(adjMines, CELLSIZE / 2, CELLSIZE / 2);
      }
    } else {

      // draw normal tile
      image(imgNormal, 0, 0);

      // draw flag
      if (flagged) {
        image(imgFlag, 0, 0);
      }
    }

    // reveal mines
    if (showMines && mine) {
      image(imgMine, 0, 0);
    }

    popMatrix();
  }
}

// contains all information for a minesweeper game
class Board {
  Cell[][] cells;      // 2D array of Cells, row-based
  EffectsLayer fx;     // ripple effect
  int boardWidth;      // width of cell grid
  int boardHeight;     // height of cell grid
  int mines;           // # of mines on board
  int flags;           // # of flagged cells
  int startMillis = 0; // value of millis() at the start of game
  float time = 0;      // time elapsed since start of game
  boolean enableFx;    // ripple effect enabled?
  int state = NEWGAME; // game state

  Board(int _boardWidth,
        int _boardHeight,
        int _mines,
        boolean _enableFx,
        int fxAmplitude) {
    this.cells       = new Cell[_boardHeight][_boardWidth];
    this.boardWidth  = _boardWidth;
    this.boardHeight = _boardHeight;
    this.mines       = _mines;
    this.enableFx    = _enableFx;

    for (int row = 0; row < boardHeight; row++) {
      for (int col = 0; col < boardWidth; col++) {
        cells[row][col] = new Cell(row, col);
      }
    }

    fx = new EffectsLayer(this, fxAmplitude);
  }

  int getWidth() {
    return boardWidth;
  }

  int getHeight() {
    return boardHeight;
  }

  // returns the cell at row, col
  Cell cell(int row, int col) {
    return cells[row][col];
  }

  // randomly disperse mines on board
  void placeMines(Cell clickedCell) {
    Cell cell;
    int count = 0;

    while(count < mines) {

      // pick a random grid spot
      cell = cells[(int)random(boardHeight)][(int)random(boardWidth)];

      // if it's not already a mine and not the provided cell, set a mine
      if (!cell.isMine() && cell != clickedCell) {
        cell.setMine();
        count++;
      }
    }

    calculateMines();
  }

  // hooks the mouse into Board using Processing mouse variables
  void hookMouse() {
    if (state == NEWGAME || state == RUNNING) {
      int row = (int) (mouseY / CELLSIZE);
      int col = (int) (mouseX / CELLSIZE);

      Cell clickedCell = cells[row][col];

      if (mouseButton == LEFT) {

        // shift + left click
        if (keyPressed == true &&
            key        == CODED &&
            keyCode    == SHIFT) {
          clickChord(clickedCell);

        // left click
        } else {
          clickReveal(clickedCell);
        }

      // middle click
      } else if (mouseButton == CENTER) {
        clickChord(clickedCell);

      // right click
      } else {
        clickFlag(clickedCell);
      }

      // create ripple
      fx.ripple(clickedCell);

    // game is not running, restart game
    } else {
      newGame();
    }
  }

  // calculate and store mine counts of each cell
  void calculateMines() {
    for (int row = 0; row < boardHeight; row++) {
      for (int col = 0; col < boardWidth; col++) {
        int adjCount = 0;

        for (Cell cell : neighbors(cells[row][col])) {
          if (cell.isMine()) {
            adjCount++;
          }
        }

        cells[row][col].setAdjMines(adjCount);
      }
    }
  }

  // reveals a cell, places mines if it's the first click
  void clickReveal(Cell cell) {
    if (cell.isMine()) {
      state = GAMELOST;
    } else {

      if (state == NEWGAME) {
        placeMines(cell);
        state = RUNNING;
        startMillis = millis();
      }

      revealCell(cell);

      if (won()) {
        state = GAMEWON;
      }
    }
  }

  // flag a cell
  void clickFlag(Cell cell) {
    cell.toggleFlagged();

    flags += cell.isFlagged() ? 1 : -1;
  }

  // "chord" click a cell
  void clickChord(Cell cell) {
    if (cell.isRevealed()) {

      // count how many adjacent flags there are
      int flaggedCount = 0;

      for (Cell neighbor : neighbors(cell)) {
        if (neighbor.isFlagged()) {
          flaggedCount++;
        }
      }

      // if equal to adjMines of that cell, reveal adjacent non-flag cells
      if (flaggedCount == cell.getAdjMines()) {
        for (Cell neighbor : neighbors(cell)) {
          if (!neighbor.isFlagged() && !neighbor.isRevealed()) {
            clickReveal(neighbor);
          }
        }
      }
    }
  }

  // return true if all non-mine cells are revealed
  boolean won() {

    for (int row = 0; row < boardHeight; row++) {
      for (int col = 0; col < boardWidth; col++) {
        if (!cells[row][col].isRevealed() && !cells[row][col].isMine()) {

          // return false when a non-revealed non-mine is detected
          return false;
        }
      }
    }

    return true;
  }

  // reveal a cell and it's connected zeros
  void revealCell(Cell cell) {
    if (!cell.isRevealed()) {
      cell.setRevealed();

      if (cell.getAdjMines() == 0) {
        for (Cell zero : findConnectedZeros(cell)) {
          zero.setRevealed();
          for (Cell edge : neighbors(zero)) {
            edge.setRevealed();
          }
        }
      }
    }
  }

  // reset the board
  void newGame() {

    // reset each cell
    for (int row = 0; row < boardHeight; row++) {
      for (int col = 0; col < boardWidth; col++) {
        cells[row][col].reset();
      }
    }

    // reset board variables
    state = NEWGAME;
    time = 0;
    flags = 0;
  }

  // return an array of adjacent cells of a given cell
  ArrayList<Cell> neighbors(Cell cell) {
    ArrayList<Cell> result = new ArrayList<Cell>();

    for (int[] direction : DIRECTIONS) {

      // add each direction difference to cell coordinates
      int neighborRow = cell.getRow() + direction[1];
      int neighborCol = cell.getCol() + direction[0];

      // check if in bounds
      if (neighborRow >= 0 && neighborRow < boardHeight) {
        if (neighborCol >= 0 && neighborCol < boardWidth) {
          result.add(cells[neighborRow][neighborCol]);
        }
      }
    }

    return result;
  }

  // return all continuous zeros given a zero
  ArrayList<Cell> findConnectedZeros(Cell zero) {
    Cell curCell;

    // resulting array of connected zeros
    ArrayList<Cell> zeros = new ArrayList<Cell>();

    // queue of cells to be traversed
    ArrayList<Cell> queue = new ArrayList<Cell>();

    // add the clicked cell to the queue
    queue.add(zero);

    while (queue.size() > 0) {

      // pop the first cell from the queue and use it as the current cell
      curCell = queue.get(0);
      queue.remove(0);

      zeros.add(curCell);

      // for all adjacent zeros of the current cell
      for (Cell neighbor : neighbors(curCell)) {
        if (neighbor.getAdjMines() == 0) {
          if (!zeros.contains(neighbor) && !queue.contains(neighbor)) {

            // add each zero to the queue if not already in zeros or queue
            queue.add(neighbor);
          }
        }
      }
    }

    return zeros;
  }

  // displays a message with a background color
  void messageBox(String message, color c) {

    // fill screen with transparent overlay
    fill(c);
    rect(0, 0, width, height);

    // print message in middle of screen
    fill(255);
    text(message, width / 2, height / 2);
  }

  // OS-dependant strings
  String timeStr, bombStr;

  // draw the board
  void drawBoard() {

    // set & format time
    if (state == RUNNING) {
      time = (millis() - startMillis) * 0.001;
    }

    if (!online) {

      // use emojis in title if mac
      String OS = System.getProperty("os.name").toLowerCase();

      if (OS.indexOf("mac") >= 0) {
        timeStr = "\u23F0";
        bombStr = "\uD83D\uDCA3";
      } else {
        timeStr = "Time";
        bombStr = "Bombs";
      }

      // sets the title of the window to reflect time remaining and bombs left
      frame.setTitle(timeStr + ": " + String.format("%.3f ", time) +
                     bombStr + ": " + (mines - flags));
    }

    for (int row = 0; row < boardHeight; row++) {
      for (int col = 0; col < boardWidth; col++) {

        // draw each cell, revealing mines if game is over
        cells[row][col].drawCell(state == GAMELOST || state == GAMEWON);

        if ((int) (mouseY / CELLSIZE) == row &&
            (int) (mouseX / CELLSIZE) == col &&
            !cells[row][col].isRevealed()) {

          // highlight cell under mouse
          fill(255, 50);

          if (mousePressed) {

            // darken if mouse pressed
            fill(0, 30);
          }

          // draw highlight/darken overlay
          rect(col * CELLSIZE, row * CELLSIZE, CELLSIZE, CELLSIZE);
        }
      }
    }

    if (enableFx) {
      fx.updateWaves();
      fx.drawWaves();
    }

    if (state == GAMELOST) {
      messageBox("Game over!\nClick to start a new game.", color(255, 0, 0, 100));
    }

    if (state == GAMEWON) {
      messageBox("You win!\nClick to start a new game.", color(50, 100));
    }
  }
}

// creates a ripple/wave effect on the grid
class EffectsLayer {
  Board board;
  float[][] buffer1, buffer2;
  int w, h, fxAmplitude;

  EffectsLayer(Board _board, int _fxAmplitude) {
    this.board = _board;
    this.fxAmplitude = _fxAmplitude;
    w = board.getWidth();
    h = board.getHeight();

    // create 2 2D arrays of values the same size as the Board
    buffer1 = new float[h][w];
    buffer2 = new float[h][w];
  }

  // creates a ripple
  void ripple(Cell cell) {
    buffer1[cell.getRow()][cell.getCol()] = fxAmplitude;
  }

  void updateWaves() {
    for (int row = 0; row < h; row++) {
      for (int col = 0; col < w; col++) {
        float x1, x2, y1, y2;

        // sum of 4 adjacent values
        y1 = (row == 0)     ? 0 : buffer1[row - 1][col];
        y2 = (row == h - 1) ? 0 : buffer1[row + 1][col];
        x1 = (col == 0)     ? 0 : buffer1[row][col - 1];
        x2 = (col == w - 1) ? 0 : buffer1[row][col + 1];

        buffer2[row][col] = (x1 + x2 + y1 + y2) / 2 - buffer2[row][col];
        buffer1[row][col] += (buffer2[row][col] - buffer1[row][col]) / 4;
      }
    }

    // swap buffers
    float[][] temp = buffer1;
    buffer1 = buffer2;
    buffer2 = temp;
  }

  void drawWaves() {
    for (int row = 0; row < h; row++) {
      for (int col = 0; col < w; col++) {
        pushMatrix();
        translate(col * CELLSIZE, row * CELLSIZE);

        // white + more alpha on default graphics
        if (!ALTIMAGES) {
          fill(255, buffer1[row][col] * 50);

        // black + less alpha on alt graphics
        } else {
          fill(0, buffer1[row][col] * 5);
        }

        rect(0, 0, CELLSIZE, CELLSIZE);
        popMatrix();
      }
    }
  }
}


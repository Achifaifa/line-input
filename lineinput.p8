pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- Line!! input!!!
-- second line

function debug(text)
  printh(text,"lineinput_debug")
end

function _init()

  --Clear debug file
  printh("init","lineinput_debug",true)

  --Game state.
  --0: Splash screen
  --1: title screen
  --2: Normal game
  --3: Game over screen
  state=2 --start directly on game (testing)
  --BGM selection (default at 1)
  bgm=1
  --beat data, one array of notes for each song (selectable with bgm variable)
  --should probably figure out a better way
  beatdata={{1,0,0,0,1,0,0,0,1,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,2,0,0,0}}

  --Piece list
  pieces={}
  pieces[1]={{15,15},{15,15}} --square
  pieces[2]={{14},{14},{14},{14}} --line
  pieces[3]={{13,13,0},{0,13,13}} --z1
  pieces[4]={{0,12,12},{12,12,0}} --z2
  pieces[5]={{0,11},{0,11},{11,11}} --l1
  pieces[6]={{10,0},{10,0},{10,10}} --l2

  --colour palette for missed note indicator
  missedcolours={15,11,9,8,5}

  --previous game init for testing
  initgame()
end

--initialize game state, should be called before every game
function initgame()

  --create block area
  grid={}
  for i=1,25 do --Block field height
    grid[i]={}
    for j=1,10 do --Block field width
      grid[i][j]=0 
    end
  end

  nextpiece=rnd(pieces)
  currentpiece={{0,4},rnd(pieces)}
  speed=8 --Once in how many notes the piece goes down
  lastmbeat=-1 --Last beat in which a piece moved
  lastcbeat=-1 --Last beat in which a combo happened
  combomark=0 --changed to 1 if there was a combo beat in a loop
  missednotes=4 --missed notes while in combo. breaks if 4
  lastseek=-1
  score=0 --total points
  lines=0 --lines cleared
  combo=0 --current combo counter

  --populate array of notes
  notes=beatdata[bgm]
  --extend array of notes to prevent continuity breaks
  --(Only for visuals, notes still 1 to 32)
  ln=#notes
  for i=1,#beatdata[bgm] do
    notes[ln+i]=beatdata[bgm][i]
  end

  --play music
  music(bgm-1) --this one starts on zero because why not
end

function draw_block_area()

  --area border
  rect(30,13,72,115)

  --main grid
  for i=1,#grid do 
    for j=1,#grid[i] do
      rectfill(27+(j*4),10+(i*4) ,31+(j*4),14+(i*4) ,grid[i][j])
    end
  end

  --current piece
  cpiecexpos=currentpiece[1][2]
  cpieceypos=currentpiece[1][1]
  for i=1,#currentpiece[2] do 
    for j=1,#currentpiece[2][i] do
      if(currentpiece[2][i][j]!=0) do
        txp=(cpiecexpos+j)*4
        typ=(cpieceypos+i)*4
        rectfill(27+txp,10+typ ,31+txp-1,14+typ ,currentpiece[2][i][j])
      end
    end
  end

  --reset colour
  color()
end

function draw_note_area()

  --beat line
  line(80,30,120,30,missedcolours[missednotes+1]) 
  --beats
  for i=1,#notes do
    if(notes[i]==1) do
      circfill(100, 30+8*(i-1-stat(20)) ,4,9)
    end
    if(notes[i]==2) do
      circfill(100, 30+8*(i-1-stat(20)) ,6,8)
      print("DROP!", 92, 28+8*(i-1-stat(20)), 15)
    end
  end
  --remove notes over and under block area height
  rectfill(73,0,125,13,0)
  rectfill(73,116,125,128,0)
  --reset colour
  color()
end

function draw_score_area()

  --score, lines
  print(score, 0,0)
  line(0,7,20,7)
  print(lines, 0,10)
  --next piece
  print("next", 0,20)
  for i=1,#nextpiece do 
    for j=1,#nextpiece[i] do
      rectfill(1+(j*4),27+(i*4) ,5+(j*4),31+(i*4) ,nextpiece[i][j])
    end
  end
  color()
  --speed
  print("spd",0,50)
  print(speed,15,50)
  --combo display
  if(combo>0)do
    print("combo",80, 7)
    print(combo, 110, 5)
  end
end

function _draw()

  cls()
  --splash screen
  if (state==0) then
    print ("splash screen",5,5)
  end
  --main menu
  if (state==1) then
    print ("line input",40,45)
    print ("bgm [1] 2 3", 38, 55)
    print ("spd [1] 2 3", 38, 60)
    print ("press x to start", 27, 65)
  end
  --game loop
  if (state==2) then
    draw_block_area()
    draw_note_area()
    draw_score_area()
  end
end

--returns the nearest valid beat (if any)
--to-do doesn't work well
function keypress_timing()

  note=stat(20)+1
  cbeat=notes[note]
  if(cbeat!=0) then return cbeat end
  if(note==1)do
    pbeat=notes[32]
    nbeat=notes[1]
  elseif(note==32)then
    pbeat=notes[31]
    nbeat=notes[1]
  else
    nbeat=notes[note+1]
    pbeat=notes[note-1]
  end
  if(pbeat!=0)then return pbeat end
  if(nbeat!=0)then return nbeat end

  return 0
end

--rotates current piece
--0 ccw, 1 cw (to-do)
function rotator(cw)

  --this fucking sucks. copy data to restore later if needed
  local coordbackup={currentpiece[1][1],currentpiece[1][2]}
  local piecebackup={}
  for i=1,#currentpiece[2] do
    piecebackup[i]={}
    for j=1,#currentpiece[2][1] do 
      piecebackup[i][j]=currentpiece[2][i][j]
    end
  end

  --piece rotation
  local oldpiece=currentpiece[2]
  local newpiece={}
  for i=1,#oldpiece[1] do
    newpiece[i]={}
    for j=1,#oldpiece do 
      newpiece[i][j]=oldpiece[j][i]
    end 
  end
  nnp={}
  for i=1,#newpiece do
    nnp[#newpiece-i+1]=newpiece[i]
  end
  currentpiece[2]=nnp

  --Correct stick coordinates
  if (currentpiece[1][1]==14) do
    if(#nnp==1)do 
      currentpiece[1][1]=currentpiece[1][1]+1 
      currentpiece[1][2]=currentpiece[1][2]-1 
    else 
      currentpiece[1][1]=currentpiece[1][1]-1 
      currentpiece[1][2]=currentpiece[1][2]+1 
    end 
  end

  --Adjust if out of bounds
  if(currentpiece[1][2]<0) then currentpiece[1][2]=0 end 
  if(currentpiece[1][2]+#currentpiece[2][1]>10) then currentpiece[1][2]=10-#currentpiece[2][1] end

  --If there are pieces in the way, revert back
  if(collisionator()==-1)do
    currentpiece={coordbackup, piecebackup}
  end
end

--increases combo if the beat is of the type specified, resets it otherwise
function comboer(cbtype)
  
  --timing data
  tmdata=keypress_timing()
  --to-do can't make this bullshit process several presses in the same note as invalid combos
  if(tmdata==cbtype) do 
    combo=combo+1
    missednotes=-1
    if(missednotes<0)then missednotes=0 end
    combomark=1
    lastcbeat=stat(20)
    score=score+ceil(combo/10)
    return
  else 
    combo=0
    combomark=0
    lastcbeat=-1
    missednotes=4
  end
end

--checks if the past note has been pressed
function notechecker()

  --skip if there's no combo going
  if(combo==0)then return end

  --seek previous note
  local seeknote=stat(20)
  while(notes[seeknote]==0)do
    if(seeknote==0)do
      seeknote=32
    else
      seeknote=seeknote-1
    end
  end

  if(seeknote==lastseek)then return end

  --if that note wasn't hit, increase missed note counter
  if(abs(seeknote-lastcbeat)>1)do
    missednotes+=1
    lastseek=seeknote
    if(missednotes==4)do 
      lastcbeat=-1
      combo=0
      combomark=0
    end 
  end 
end

--0 if everything is ok, 1 if the piece is on bottom or over something, -1 if game over
function collisionator()

  res=0

  --detect surroundings
  local piece=currentpiece[2]
  local xc=currentpiece[1][2]
  local yc=currentpiece[1][1]
  for i=1,#piece do
    for j=1,#piece[1] do 
      if(piece[i][j]!=0 and yc+#piece<25)do 
        --check if it collides with background
        if (grid[yc+i][xc+j]!=0) then return -1 end 
        --check if there are things below
        if (grid[yc+i+1][xc+j]!=0) do
          res=1 
        end 
      end 
    end 
  end

  --piece at bottom
  if(currentpiece[1][1]+#currentpiece[2]>24) then return 1 end

  return res
end


function fuse()

  local collisions=collisionator()
  if(collisions==1)do 
    --fuse piece on grid
    local piece=currentpiece[2]
    for i=1,#piece do 
      for j=1, #piece[1] do 
        if(piece[i][j]!=0)do
          grid[currentpiece[1][1]+i][currentpiece[1][2]+j]=piece[i][j]
        end
      end 
    end 

    --process lines
    local newgrid={}
    local flines=0
    for i=1,#grid do 
      local full=1
      for j=1,#grid[1] do 
        if(grid[#grid-i+1][j]==0) then full=0 end
      end
      if(full==1)do 
        flines=flines+1
      else 
        newgrid[#grid-i+1+flines]=grid[#grid-i+1]
      end 
    end
    for i=1,flines do 
      newgrid[i]={}
      for j=1,10 do --Block field width
        newgrid[i][j]=0 
      end
    end 
    grid=newgrid

    --process line score
    if(flines>0)do
      local mscore=0
      if(flines==1)do
        mscore=mscore+50
      elseif(flines==2)then
        mscore=mscore+100
      elseif(fline==3)then
        mscore=mscore+200
      else
        mscore=mscore+500
      end
      if(combomark==1) then mscore=mscore+mscore*flr(combo/10) end
      score=score+mscore
      lines=lines+flines
    end

    --generate new piece
    currentpiece={{0,4},nextpiece}
    nextpiece=rnd(pieces)

    --check if new piece collides
    if(collisionator()==-1) then  end --to-do game over
  end
end

function _update()

  --game logic
  if(state==2)then

    --move piece down per timing
    if (stat(20)%speed==0) then
      if (lastmbeat!=stat(20)) then
        fuse()
        currentpiece[1][1]=currentpiece[1][1]+1 
        lastmbeat=stat(20)
      end
    end
    
    --controls (LRUD OX -> 0..6)
    if(btnp(0))do --left
      if(currentpiece[1][2]-1>=0)do
        currentpiece[1][2]=currentpiece[1][2]-1
        comboer(1)
      end
    end
    if(btnp(1))do --right
      if(currentpiece[1][2]+1+#currentpiece[2][1]<11)do
        currentpiece[1][2]=currentpiece[1][2]+1
        comboer(1)
      end
    end
    if(btnp(2))do --up (fast drop) 
      while(collisionator()!=1)do 
        currentpiece[1][1]=currentpiece[1][1]+1
      end
      fuse()
      comboer(2)
    end
    if(btnp(3))do --down
      fuse()
      currentpiece[1][1]=currentpiece[1][1]+1
      comboer(1)
    end
    if(btnp(4))do --O (Rotate left)
      rotator(0)
      comboer(1)
    end
    if(btnp(5))do --X (Rotate right)
      rotator(1)
      comboer(1)
    end
    combomark=0

    --check for missed notes
    if (stat(20)%4) then notechecker() end

  end

  --title to game
  if(state==1)then
    if(btnp(4)) then 
      state=state+1
      initgame()
    end
  end

  --splash to title
  if(state==0)then
    if(btnp(4)) then 
      state=state+1
    end
  end

end
__sfx__
000100000d05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001400000d3500000000000000000d3500000000000000000d3500000000000000000f3500000000000000000d3500000000000000000d3500000000000000000d3500000000000000000f350000000000000000
__music__
03 01424344


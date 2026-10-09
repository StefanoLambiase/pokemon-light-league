pbCompiler

#region Quest system
#===============================================================================
# Modern Questing System + UI
# If you like quests, this is the resource for you!
#===============================================================================
# Original implemenation by mej71
# Updated for v17.2 and v18/18.1 by derFischae
# Heavily edited for v19/19.1 by ThatWelshOne_
# Some UI components borrowed (with permission) from Marin's Easy Questing Interface
# 
#===============================================================================
# Things you can currently customise without editing the scripts themselves
#===============================================================================

# If true, includes a page of failed quests on the UI
# Set this to false if you don't want to have quests that can be failed
SHOW_FAILED_QUESTS = true

# Name of file in Audio/SE that plays when a quest is activated/advanced to new stage/completed
QUEST_JINGLE = "Mining found all.ogg"

# Name of file in Audio/SE that plays when a quest is failed
QUEST_FAIL = "GUI sel buzzer.ogg"

# Future plans are to add different backgrounds that can be chosen by you

#===============================================================================
# Utility method for setting colors
#===============================================================================

# Useful Hex to 15-bit color converter: http://www.budmelvin.com/dev/15bitconverter.html
# Add in your own colors here!
def colorQuest(color)
  color = color.downcase if color
  return "7DC076EF" if color == "blue"
  return "089D5EBF" if color == "red"
  return "26CC4B56" if color == "green"
  return "6F697395" if color == "cyan"
  return "5CFA729D" if color == "magenta"
  return "135D47BF" if color == "yellow"
  return "56946F5A" if color == "gray"
  return "7FDE6B39" if color == "white"
  return "751272B7" if color == "purple"
  return "0E7F4F3F" if color == "orange"
  return "2D4A5694" # Returns the default dark gray color if all other options are exhausted
end

#===============================================================================
# This class holds the information for an individual quest
#===============================================================================
class Quest
  attr_accessor :id
  attr_accessor :stage
  attr_accessor :time
  attr_accessor :location
  attr_accessor :new
  attr_accessor :color
  attr_accessor :story

  def initialize(id,color,story)
    self.id       = id
    self.stage    = 1
    self.time     = Time.now
    self.location = $game_map.name
    self.new      = true
    self.color    = color
    self.story    = story
  end
  
  def stage=(value)
    if value > $quest_data.getMaxStagesForQuest(self.id)
      value = $quest_data.getMaxStagesForQuest(self.id)
    end
    @stage = value
  end
end

#===============================================================================
# This class holds all the trainers quests
#===============================================================================
class Player_Quests
  attr_accessor :active_quests
  attr_accessor :completed_quests
  attr_accessor :failed_quests
  attr_accessor :selected_quest_id
  
  def initialize
    @active_quests     = []
    @completed_quests  = []
    @failed_quests     = []
    @selected_quest_id = 0
  end
  
  # questID should be the symbolic name of the quest, e.g. :Quest1
  def activateQuest(quest,color,story)
    if !quest.is_a?(Symbol)
      raise _INTL("The 'quest' argument should be a symbol, e.g. ':Quest1'.")
    end
    for i in 0...@active_quests.length
      if @active_quests[i].id == quest
        pbMessage("You have already started this quest.")
        return
      end
    end
    for i in 0...@completed_quests.length
      if @completed_quests[i].id == quest
        pbMessage("You have already completed this quest.")
        return
      end
    end
    for i in 0...@failed_quests.length
      if @failed_quests[i].id == quest
        pbMessage("You have already failed this quest.")
        return
      end
    end
    @active_quests.push(Quest.new(quest,color,story))
    pbMessage(_INTL("\\se[{1}]<ac><c2=#{colorQuest("red")}>New quest discovered!</c2>\nCheck your quest log for more details!</ac>",QUEST_JINGLE))
  end
  
  def failQuest(quest,color,story)
    if !quest.is_a?(Symbol)
      raise _INTL("The 'quest' argument should be a symbol, e.g. ':Quest1'.")
    end
    found = false
    for i in 0...@completed_quests.length
      if @completed_quests[i].id == quest
        pbMessage("You have already completed this quest.")
        return
      end
    end
    for i in 0...@failed_quests.length
      if @failed_quests[i].id == quest
        pbMessage("You have already failed this quest.")
        return
      end
    end 
    for i in 0...@active_quests.length
      if @active_quests[i].id == quest
        temp_quest = @active_quests[i]
        temp_quest.color = color if color != nil
        temp_quest.new = true # Setting this back to true makes the "!" icon appear when the quest updates
        temp_quest.time = Time.now
        @failed_quests.push(temp_quest)
        @active_quests.delete_at(i)
        found = true
        pbMessage(_INTL("\\se[{1}]<ac><c2=#{colorQuest("red")}>Quest failed!</c2>\nYour quest log has been updated!</ac>",QUEST_FAIL))
        break
      end
    end
    if !found
      color = colorQuest(nil) if color == nil
      @failed_quests.push(Quest.new(quest,color,story))
    end
  end
  
  def completeQuest(quest,color,story)
    if !quest.is_a?(Symbol)
      raise _INTL("The 'quest' argument should be a symbol, e.g. ':Quest1'.")
    end
    found = false
    for i in 0...@completed_quests.length
      if @completed_quests[i].id == quest
        pbMessage("You have already completed this quest.")
        return
      end
    end
    for i in 0...@failed_quests.length
      if @failed_quests[i].id == quest
        pbMessage("You have already failed this quest.")
        return
      end
    end  
    for i in 0...@active_quests.length
      if @active_quests[i].id == quest
        temp_quest = @active_quests[i]
        temp_quest.color = color if color != nil
        temp_quest.new = true # Setting this back to true makes the "!" icon appear when the quest updates
        temp_quest.time = Time.now
        @completed_quests.push(temp_quest)
        @active_quests.delete_at(i)
        found = true
        pbMessage(_INTL("\\se[{1}]<ac><c2=#{colorQuest("red")}>Quest completed!</c2>\nYour quest log has been updated!</ac>",QUEST_JINGLE))
        break
      end
    end
    if !found
      color = colorQuest(nil) if color == nil
      @completed_quests.push(Quest.new(quest,color,story))
    end
  end
  
  def advanceQuestToStage(quest,stageNum,color,story)
    if !quest.is_a?(Symbol)
      raise _INTL("The 'quest' argument should be a symbol, e.g. ':Quest1'.")
    end
    found = false
    for i in 0...@active_quests.length
      if @active_quests[i].id == quest
        @active_quests[i].stage = stageNum
        @active_quests[i].color = color if color != nil
        @active_quests[i].new = true # Setting this back to true makes the "!" icon appear when the quest updates
        found = true
        pbMessage(_INTL("\\se[{1}]<ac><c2=#{colorQuest("red")}>New task added!</c2>\nYour quest log has been updated!</ac>",QUEST_JINGLE))
      end
      return if found
    end
    if !found
      color = colorQuest(nil) if color == nil
      questNew = Quest.new(quest,color,story)
      questNew.stage = stageNum
      @active_quests.push(questNew)
    end
  end
end

#===============================================================================
# Initiate quest data
#===============================================================================
class PokemonGlobalMetadata  
  def quests
    @quests = Player_Quests.new if !@quests
    return @quests
  end
  
  alias quest_init initialize
  def initialize
    quest_init
    @quests = Player_Quests.new
  end
end

#===============================================================================
# Helper and utility functions for managing quests
#===============================================================================

# Helper function for activating quests
def activateQuest(quest,color=colorQuest(nil),story=false)
  return if !$PokemonGlobal
  $PokemonGlobal.quests.activateQuest(quest,color,story)
end

# Helper function for marking quests as completed
def completeQuest(quest,color=nil,story=false)
  return if !$PokemonGlobal
  $PokemonGlobal.quests.completeQuest(quest,color,story)
end

# Helper function for marking quests as failed
def failQuest(quest,color=nil,story=false)
  return if !$PokemonGlobal
  $PokemonGlobal.quests.failQuest(quest,color,story)
end

# Helper function for advancing quests to given stage
def advanceQuestToStage(quest,stageNum,color=nil,story=false)
  return if !$PokemonGlobal
  $PokemonGlobal.quests.advanceQuestToStage(quest,stageNum,color,story)
end

# Get symbolic names of active quests
# Unused
def getActiveQuests
  active = []
  $PokemonGlobal.quests.active_quests.each do |s|
    active.push(s.id)
  end
  return active
end

# Get symbolic names of completed quests
# Unused
def getCompletedQuests
  completed = []
  $PokemonGlobal.quests.completed_quests.each do |s|
    completed.push(s.id)
  end
  return completed
end

# Get symbolic names of failed quests
# Unused
def getFailedQuests
  failed = []
  $PokemonGlobal.quests.failed_quests.each do |s|
    failed.push(s.id)
  end
  return failed
end

#===============================================================================
# Class that contains utility methods to return quest properties
#===============================================================================
class QuestData

  # Get ID number for quest
  def getID(quest)
    return "#{QuestModule.const_get(quest)[:ID]}"
  end

  # Get quest name
  def getName(quest)
    return "#{QuestModule.const_get(quest)[:Name]}"
  end

  # Get name of quest giver
  def getQuestGiver(quest)
    return "#{QuestModule.const_get(quest)[:QuestGiver]}"
  end

  # Get array of quest stages
  def getQuestStages(quest)
    arr = []
    for key in QuestModule.const_get(quest).keys
      arr.push(key) if key.to_s.include?("Stage")
    end
    return arr
  end

  # Get quest reward
  def getQuestReward(quest)
    return "#{QuestModule.const_get(quest)[:RewardString]}"
  end

  # Get overall quest description
  def getQuestDescription(quest)
    return "#{QuestModule.const_get(quest)[:QuestDescription]}"
  end

  # Get current task location
  def getStageLocation(quest,stage)
    loc = ("Location" + "#{stage}").to_sym
    return "#{QuestModule.const_get(quest)[loc]}"
  end  

  # Get summary of current task
  def getStageDescription(quest,stage)
    stg = ("Stage" + "#{stage}").to_sym
    return "#{QuestModule.const_get(quest)[stg]}"
  end 

  # Get maximum number of tasks for quest
  def getMaxStagesForQuest(quest)
    quests = getQuestStages(quest)
    return quests.length
  end
  
end

# Global variable to make it easier to refer to methods in above class
$quest_data = QuestData.new

#===============================================================================
# Class that contains utility methods to return quest properties
#===============================================================================

# Utility function to check whether the player current has any quests
def hasAnyQuests?
  if $PokemonGlobal.quests.active_quests.length >0 || 
    $PokemonGlobal.quests.completed_quests.length >0 ||
    $PokemonGlobal.quests.failed_quests.length >0
    return true
  end
  return false      
end

#===============================================================================
# Class that creates the scrolling list of quest names
#===============================================================================
class Window_Quest < Window_DrawableCommand

  def initialize(x,y,width,height,viewport)
    @quests = []
    super(x,y,width,height,viewport)
    self.windowskin = nil
    @selarrow = AnimatedBitmap.new("Graphics/Pictures/selarrow")
  end
  
  def quests=(value)
    @quests = value
    refresh
  end
  
  def itemCount
    return @quests.length
  end
  
  def drawItem(index,_count,rect)
    return if index>=self.top_row+self.page_item_max
    rect = Rect.new(rect.x+16,rect.y,rect.width-16,rect.height)
    name = $quest_data.getName(@quests[index].id)
    name = "<b>" + "#{name}" + "</b>" if @quests[index].story
    base = self.baseColor
    shadow = self.shadowColor
    col = @quests[index].color
    drawFormattedTextEx(self.contents,rect.x,rect.y+4,
      436,"<c2=#{col}>#{name}</c2>",base,shadow)
    pbDrawImagePositions(self.contents,[[sprintf("Graphics/Pictures/QuestUI/new"),rect.width-16,rect.y+2]]) if @quests[index].new
  end

  def refresh
    @item_max = itemCount
    dwidth  = self.width-self.borderX
    dheight = self.height-self.borderY
    self.contents = pbDoEnsureBitmap(self.contents,dwidth,dheight)
    self.contents.clear
    for i in 0...@item_max
      next if i<self.top_item || i>self.top_item+self.page_item_max
      drawItem(i,@item_max,itemRect(i))
    end
    drawCursor(self.index,itemRect(self.index)) if itemCount >0
  end
  
  def update
    super
    @uparrow.visible   = false
    @downarrow.visible = false
  end
end

#===============================================================================
# Class that controls the UI
#===============================================================================
class QuestList_Scene
  
  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @base = Color.new(80,80,88)
    @shadow = Color.new(160,160,168)
    addBackgroundPlane(@sprites,"bg","QuestUI/bg_1",@viewport)
    @sprites["base"] = IconSprite.new(0,0,@viewport)
    @sprites["base"].setBitmap("Graphics/Pictures/QuestUI/bg_2")
    @sprites["page_icon1"] = IconSprite.new(0,4,@viewport)
    if SHOW_FAILED_QUESTS
      @sprites["page_icon1"].setBitmap("Graphics/Pictures/QuestUI/page_icon1a")
    else
      @sprites["page_icon1"].setBitmap("Graphics/Pictures/QuestUI/page_icon1b")
    end
    @sprites["page_icon1"].x = Graphics.width - @sprites["page_icon1"].bitmap.width - 10
    @sprites["page_icon2"] = IconSprite.new(0,4,@viewport)
    @sprites["page_icon2"].setBitmap("Graphics/Pictures/QuestUI/page_icon2")
    @sprites["page_icon2"].x = Graphics.width - @sprites["page_icon2"].bitmap.width - 10
    @sprites["page_icon2"].opacity = 0
    @sprites["pageIcon"] = IconSprite.new(@sprites["page_icon1"].x,4,@viewport)
    @sprites["pageIcon"].setBitmap("Graphics/Pictures/QuestUI/pageIcon")
    @quests = [
      $PokemonGlobal.quests.active_quests,
      $PokemonGlobal.quests.completed_quests
    ]
    @quests_text = ["Active", "Completed"]
    if SHOW_FAILED_QUESTS
      @quests.push($PokemonGlobal.quests.failed_quests)
      @quests_text.push("Failed")
    end
    @current_quest = 0
    @sprites["itemlist"] = Window_Quest.new(22,28,Graphics.width-22,Graphics.height-80,@viewport)
    @sprites["itemlist"].index = 0
    @sprites["itemlist"].baseColor = @base
    @sprites["itemlist"].shadowColor = @shadow
    @sprites["itemlist"].quests = @quests[@current_quest]
    @sprites["overlay1"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay1"].bitmap)
    @sprites["overlay2"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["overlay2"].opacity = 0
    pbSetSystemFont(@sprites["overlay2"].bitmap)
    @sprites["overlay3"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["overlay3"].opacity = 0
    pbSetSystemFont(@sprites["overlay3"].bitmap)
    @sprites["overlay_control"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay_control"].bitmap)
    pbDrawTextPositions(@sprites["overlay1"].bitmap,[
      [_INTL("{1} tasks", @quests_text[@current_quest]),6,-2,0,Color.new(248,248,248),Color.new(0,0,0),true]
    ])
    drawFormattedTextEx(@sprites["overlay_control"].bitmap,38,316,
      436,"<c2=#{colorQuest("red")}>ARROWS:</c2> Navigate",@base,@shadow)
    drawFormattedTextEx(@sprites["overlay_control"].bitmap,38,348,
      436,"<c2=#{colorQuest("red")}>A/S:</c2> Jump Down/Up",@base,@shadow)
    drawFormattedTextEx(@sprites["overlay_control"].bitmap,326,316,
      436,"<c2=#{colorQuest("red")}>New Activity:</c2>",@base,@shadow)
    pbDrawImagePositions(@sprites["overlay_control"].bitmap,[
      [sprintf("Graphics/Pictures/QuestUI/new"),464,314]
    ])
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbScene
    loop do
      selected = @sprites["itemlist"].index
      @sprites["itemlist"].active = true
      dorefresh = false
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::B)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::C)
        if @quests[@current_quest].length==0
          pbPlayBuzzerSE
        else
          pbPlayDecisionSE
          fadeContent
          @sprites["itemlist"].active = false
          pbQuest(@quests[@current_quest][selected])
          showContent
        end
      elsif Input.trigger?(Input::RIGHT)
        pbPlayCursorSE
        @current_quest +=1; @current_quest = 0 if @current_quest > @quests.length-1
        dorefresh = true
      elsif Input.trigger?(Input::LEFT)
        pbPlayCursorSE
        @current_quest -=1; @current_quest = @quests.length-1 if @current_quest < 0
        dorefresh = true
      end
      swapQuestType if dorefresh
    end
  end
  
  def swapQuestType
    @sprites["overlay1"].bitmap.clear
    @sprites["itemlist"].index = 0 # Resets cursor position
    @sprites["itemlist"].quests = @quests[@current_quest]
    @sprites["pageIcon"].x = @sprites["page_icon1"].x + 32*@current_quest
    pbDrawTextPositions(@sprites["overlay1"].bitmap,[
      [_INTL("{1} tasks", @quests_text[@current_quest]),6,-2,0,Color.new(248,248,248),Color.new(0,0,0),true]
    ])
  end
  
  def fadeContent
    15.times do
      Graphics.update
      @sprites["itemlist"].contents_opacity -= 17
      @sprites["overlay1"].opacity -= 17; @sprites["overlay_control"].opacity -= 17
      @sprites["page_icon1"].opacity -= 17; @sprites["pageIcon"].opacity -= 17
    end
  end
  
  def showContent
    15.times do
      Graphics.update
      @sprites["itemlist"].contents_opacity += 17
      @sprites["overlay1"].opacity += 17; @sprites["overlay_control"].opacity += 17
      @sprites["page_icon1"].opacity += 17; @sprites["pageIcon"].opacity += 17
    end
  end
  
  def pbQuest(quest)
    quest.new = false
    drawQuestDesc(quest)
    15.times do
      Graphics.update
      @sprites["overlay2"].opacity += 17; @sprites["overlay3"].opacity += 17; @sprites["page_icon2"].opacity += 17
    end
    page = 1
    loop do
      Graphics.update
      Input.update
      pbUpdate
      showOtherInfo = false
      if Input.trigger?(Input::RIGHT) && page==1
        pbPlayCursorSE
        page += 1
        @sprites["page_icon2"].mirror = true
        drawOtherInfo(quest)
      elsif Input.trigger?(Input::LEFT) && page==2
        pbPlayCursorSE
        page -= 1
        @sprites["page_icon2"].mirror = false
        drawQuestDesc(quest)
      elsif Input.trigger?(Input::B)
        pbPlayCloseMenuSE
        break
      end
    end
    15.times do
      Graphics.update
      @sprites["overlay2"].opacity -= 17; @sprites["overlay3"].opacity -= 17; @sprites["page_icon2"].opacity -= 17
    end
    @sprites["page_icon2"].mirror = false
    @sprites["itemlist"].refresh
  end
  
  def drawQuestDesc(quest)
    @sprites["overlay2"].bitmap.clear; @sprites["overlay3"].bitmap.clear
    # Quest name
    questName = $quest_data.getName(quest.id)
    pbDrawTextPositions(@sprites["overlay2"].bitmap,[
      ["#{questName}",6,-2,0,Color.new(248,248,248),Color.new(0,0,0),true]
    ])
    # Quest description
    questDesc = "<c2=#{colorQuest("blue")}>Overview:</c2> #{$quest_data.getQuestDescription(quest.id)}"
    drawFormattedTextEx(@sprites["overlay3"].bitmap,38,48,
      436,questDesc,@base,@shadow)
    # Stage description
    questStageDesc = $quest_data.getStageDescription(quest.id,quest.stage)
    # Stage location
    questStageLocation = $quest_data.getStageLocation(quest.id,quest.stage)
    # If 'nil' or missing, set to '???'
    if questStageLocation=="nil" || questStageLocation==""
      questStageLocation = "???"
    end
    drawFormattedTextEx(@sprites["overlay3"].bitmap,38,316,
      436,"<c2=#{colorQuest("orange")}>Task:</c2> #{questStageDesc}",@base,@shadow)
    drawFormattedTextEx(@sprites["overlay3"].bitmap,38,348,
      436,"<c2=#{colorQuest("purple")}>Location:</c2> #{questStageLocation}",@base,@shadow)
  end

  def drawOtherInfo(quest)
    @sprites["overlay3"].bitmap.clear
    # Guest giver
    questGiver = $quest_data.getQuestGiver(quest.id)
    # If 'nil' or missing, set to '???'
    if questGiver=="nil" || questGiver==""
      questGiver = "???"
    end
    # Total number of stages for quest
    questLength = $quest_data.getMaxStagesForQuest(quest.id)
    # Map quest was originally started
    originalMap = quest.location
    # Vary text according to map name
    loc = originalMap.include?("Route") ? "on" : "in"
    # Format time
    time = quest.time.strftime("%B %d %Y %H:%M")
    if getActiveQuests.include?(quest.id)
      time_text = "start"
    elsif getCompletedQuests.include?(quest.id)
      time_text = "completion"
    else
      time_text = "failure"
    end
    # Quest reward
    questReward = $quest_data.getQuestReward(quest.id)
    if questReward=="nil" || questReward==""
      questReward = "???"
    end
    textpos = [
      [sprintf("Stage %d/%d",quest.stage,questLength),38,38,0,@base,@shadow],
      ["#{questGiver}",38,110,0,@base,@shadow],
      ["#{originalMap}",38,182,0,@base,@shadow],
      ["#{time}",38,254,0,@base,@shadow]
    ]
    drawFormattedTextEx(@sprites["overlay3"].bitmap,38,88,
      436,"<c2=#{colorQuest("cyan")}>Quest received from:</c2>",@base,@shadow)
    drawFormattedTextEx(@sprites["overlay3"].bitmap,38,160,
      436,"<c2=#{colorQuest("magenta")}>Quest discovered #{loc}:</c2>",@base,@shadow)
    drawFormattedTextEx(@sprites["overlay3"].bitmap,38,232,
      436,"<c2=#{colorQuest("green")}>Quest #{time_text} time:</c2>",@base,@shadow)
    drawFormattedTextEx(@sprites["overlay3"].bitmap,38,Graphics.height-68,
      436,"<c2=#{colorQuest("red")}>Reward:</c2> #{questReward}",@base,@shadow)
    pbDrawTextPositions(@sprites["overlay3"].bitmap,textpos)
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

#===============================================================================
# Class to call UI
#===============================================================================
class QuestList_Screen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    @scene.pbStartScene
    @scene.pbScene
    @scene.pbEndScene
  end
end

# Utility method for calling UI
def pbViewQuests
  scene = QuestList_Scene.new
  screen = QuestList_Screen.new(scene)
  screen.pbStartScreen
end

module QuestModule
  
  # You don't actually need to add any information, but the respective fields in the UI will be blank or "???"
  # I included this here mostly as an example of what not to do, but also to show it's a thing that exists
  Quest0 = {
  
  }
  
  # Here's the simplest example of a single-stage quest with everything specified
  Quest1 = {
    :ID => "1",
    :Name => "Introductions",
    :QuestGiver => "Little Boy",
    :Stage1 => "Look for clues.",
    :Location1 => "Lappet Town",
    :QuestDescription => "Some wild Pokémon stole a little boy's favourite toy. Find those troublemakers and help him get it back.",
    :RewardString => "Something shiny!"
  }
  
  # Here's an extension of the above that includes multiple stages
  Quest2 = {
    :ID => "2",
    :Name => "Introductions",
    :QuestGiver => "Little Boy",
    :Stage1 => "Look for clues.",
    :Stage2 => "Follow the trail.",
    :Stage3 => "Catch the troublemakers!",
    :Location1 => "Lappet Town",
    :Location2 => "Viridian Forest",
    :Location3 => "Route 3",
    :QuestDescription => "Some wild Pokémon stole a little boy's favourite toy. Find those troublemakers and help him get it back.",
    :RewardString => "Something shiny!"
  }
  
  # Here's an example of a quest with lots of stages that also doesn't have a stage location defined for every stage
  Quest3 = {
    :ID => "3",
    :Name => "Last-minute chores",
    :QuestGiver => "Grandma",
    :Stage1 => "A",
    :Stage2 => "B",
    :Stage3 => "C",
    :Stage4 => "D",
    :Stage5 => "E",
    :Stage6 => "F",
    :Stage7 => "G",
    :Stage8 => "H",
    :Stage9 => "I",
    :Stage10 => "J",
    :Stage11 => "K",
    :Stage12 => "L",
    :Location1 => "nil",
    :Location2 => "nil",
    :Location3 => "Dewford Town",
    :QuestDescription => "Isn't the alphabet longer than this?",
    :RewardString => "Chicken soup!"
  }
  
  # Here's an example of not defining the quest giver and reward text
  Quest4 = {
    :ID => "4",
    :Name => "A new beginning",
    :QuestGiver => "nil",
    :Stage1 => "Turning over a new leaf... literally!",
    :Stage2 => "Help your neighbours.",
    :Location1 => "Milky Way",
    :Location2 => "nil",
    :QuestDescription => "You crash landed on an alien planet. There are other humans here and they look hungry...",
    :RewardString => "nil"
  }
  
  # Other random examples you can look at if you want to fill out the UI and check out the page scrolling
  Quest5 = {
    :ID => "5",
    :Name => "All of my friends",
    :QuestGiver => "Barry",
    :Stage1 => "Meet your friends near Acuity Lake.",
    :QuestDescription => "Barry told me that he saw something cool at Acuity Lake and that I should go see. I hope it's not another trick.",
    :RewardString => "You win nothing for giving in to peer pressure."
  }
  
  Quest6 = {
    :ID => "6",
    :Name => "The journey begins",
    :QuestGiver => "Professor Oak",
    :Stage1 => "Deliver the parcel to the Pokémon Mart in Viridian City.",
    :Stage2 => "Return to the Professor.",
    :Location1 => "Viridian City",
    :Location2 => "nil",
    :QuestDescription => "The Professor has entrusted me with an important delivery for the Viridian City Pokémon Mart. This is my first task, best not mess it up!",
    :RewardString => "nil"
  }
  
  Quest7 = {
    :ID => "7",
    :Name => "Close encounters of the... first kind?",
    :QuestGiver => "nil",
    :Stage1 => "Make contact with the strange creatures.",
    :Location1 => "Rock Tunnel",
    :QuestDescription => "A sudden burst of light, and then...! What are you?",
    :RewardString => "A possible probing."
  }
  
  Quest8 = {
    :ID => "8",
    :Name => "These boots were made for walking",
    :QuestGiver => "Musician #1",
    :Stage1 => "Listen to the musician's, uhh, music.",
    :Stage2 => "Find the source of the power outage.",
    :Location1 => "nil",
    :Location2 => "Celadon City Sewers",
    :QuestDescription => "A musician was feeling down because he thinks no one likes his music. I should help him drum up some business."
  }
  
  Quest9 = {
    :ID => "9",
    :Name => "Got any grapes?",
    :QuestGiver => "Duck",
    :Stage1 => "Listen to The Duck Song.",
    :Stage2 => "Try not to sing it all day.",
    :Location1 => "YouTube",
    :QuestDescription => "Let's try to revive old memes by listening to this funny song about a duck wanting grapes.",
    :RewardString => "A loss of braincells. Hurray!"
  }
  
  Quest10 = {
    :ID => "10",
    :Name => "Singing in the rain",
    :QuestGiver => "Some old dude",
    :Stage1 => "I've run out of things to write.",
    :Stage2 => "If you're reading this, I hope you have a great day!",
    :Location1 => "Somewhere prone to rain?",
    :QuestDescription => "Whatever you want it to be.",
    :RewardString => "Wet clothes."
  }
  
  Quest11 = {
    :ID => "11",
    :Name => "When is this list going to end?",
    :QuestGiver => "Me",
    :Stage1 => "When IS this list going to end?",
    :Stage2 => "123",
    :Stage3 => "456",
    :Stage4 => "789",
    :QuestDescription => "I'm losing my sanity.",
    :RewardString => "nil"
  }
  
  Quest12 = {
    :ID => "12",
    :Name => "The laaast melon",
    :QuestGiver => "Some stupid dodo",
    :Stage1 => "Fight for the last of the food.",
    :Stage2 => "Don't die.",
    :Location1 => "A volcano/cliff thing?",
    :Location2 => "Good advice for life.",
    :QuestDescription => "Tea and biscuits, anyone?",
    :RewardString => "Food, glorious food!"
  }

  # ======================================
  # My quests ============================
  # ======================================
  Main_Odeya = {
    :ID => "13",
    :Name => "L'inizio della competizione",
    :QuestGiver => "Organizzatori",
    :Stage1 => "Raggiungi il Centro Stampa di Odeya.",
    :Location1 => "Odeya City",
    :QuestDescription => "Raggiungi Odeya per partecipare alla cerimonia di apertura della Competizione.",
    :RewardString => "nil"
  }

  Side_Gaia = {
    :ID => "14",
    :Name => "Uno strumento per Gaia",
    :QuestGiver => "Fratello di Gaia",
    :Stage1 => "Trova Gaia al monte Ani.",
    :Location1 => "Monte Ani",
    :QuestDescription => "Trova Gaia al Monte Ani e restituiscigli il suo strumento musicale.",
    :RewardString => "nil"
  }

  Side_Bimba = {
    :ID => "15",
    :Name => "La Papera che vola",
    :QuestGiver => "Bimba",
    :Stage1 => "Mostra un Porygon alla bimba.",
    :Location1 => "???",
    :Stage2 => "Trova Jirachi.",
    :Location2 => "Grande Giardino",
    :QuestDescription => "Trova un Porygon e mostralo alla bambina che ti ha donato le sue bacche.",
    :RewardString => "nil"
  }

  Main_Petraglia = {
    :ID => "16",
    :Name => "L'allenamento di Petraglia",
    :QuestGiver => "Petraglia, Superquattro",
    :Stage1 => "Azzera gli EVs di un Pokémon.",
    :Location1 => "Giardino a Nord del Percorso 4",
    :Stage2 => "Vinci tutte le lotte in doppio.",
    :Location2 => "Percorso 4",
    :QuestDescription => "Segui l'allenamento di Petraglia e azzera gli EVs di un Pokémon in tutte le statistiche con le bacche del Giardino a nord.",
    :RewardString => "nil"
  }

  Side_Zoroark = {
    :ID => "17",
    :Name => "La ricerca di Zoroark",
    :QuestGiver => "Anziano di Odeya",
    :Stage1 => "Trova Zoroark.",
    :Location1 => "???",
    :QuestDescription => "Zoroark è partito alla ricerca di un allenatore degno. Scopri dove si sta nascondendo nella regione di Rain'Bow.",
    :RewardString => "nil"
  }

  Main_Andrea = {
    :ID => "18",
    :Name => "Soci rivali",
    :QuestGiver => "Andrea",
    :Stage1 => "Sopravvivi al Percorso 6.",
    :Location1 => "Percorso 6",
    :QuestDescription => "Fai squadra con Andrea per sopravvivere ai pericoli che si annidano lungo il Percorso 6.",
    :RewardString => "nil"
  }

  Side_Slowking = {
    :ID => "19",
    :Name => "La solitudine dei geni",
    :QuestGiver => "Slowking",
    :Stage1 => "Porta a Slowking un suo simile.",
    :Location1 => "Faro del Percorso 6",
    :QuestDescription => "Cattura e fai evolvere uno SLOWPOKE per creare un amico da far conoscere allo SLOWKING che dirige il traffico marittimo.",
    :RewardString => "nil"
  }

  Side_PP = {
    :ID => "20",
    :Name => "Indagine su P.P.",
    :QuestGiver => "Maresciallo Cuomo",
    :Stage1 => "Trova P.P.",
    :Location1 => "???",
    :QuestDescription => "La malavita di Rain'Bow sta gestende un contrabbando di Pokémon. Trova il capo, P.P., ed informa Cuomo.",
    :RewardString => "nil"
  }

  Side_Alieni = {
    :ID => "21",
    :Name => "Un'invasione respinta",
    :QuestGiver => "Vecchietta del cimitero",
    :Stage1 => "Placa gli spiriti.",
    :Location1 => "???",
    :QuestDescription => "Sei monoliti marroni sono disseminati nella Regione. Trovali e placa i bollenti spiriti dei Pokémon alieni.",
    :RewardString => "nil"
  }

  Main_Samuele = {
    :ID => "22",
    :Name => "Chi muore si rivede",
    :QuestGiver => "Samuele, Superquattro",
    :Stage1 => "Recupera la piuma.",
    :Location1 => "Grotta di Fundi Village",
    :QuestDescription => "Un Pokémon risorto custodisce una piuma di Ho-Oh nella grotta di Fundi Village. Trovalo, recupera la piuma e portala a Samuele.",
    :RewardString => "nil"
  }

  Main_Melissa = {
    :ID => "23",
    :Name => "Giornalismo d'assalto!",
    :QuestGiver => "Samuele, Superquattro",
    :Stage1 => "Trova Melissa.",
    :Location1 => "Ufficio Stampa di Odeya City",
    :Stage2 => "Scorta Melissa.",
    :Location2 => "Ospedale di Odeya City",
    :QuestDescription => "Un'emergenza sta sconvolgendo Odeya City. Trova la reporter Melissa al Centro Stampa ed aiutala per conto di Samuele.",
    :RewardString => "nil"
  }

  Main_Uni = {
    :ID => "24",
    :Name => "Sfida Ufficiale! L'Università",
    :QuestGiver => "Organizzatori",
    :Stage1 => "Vinci la sfida dell'Università.",
    :Location1 => "Università",
    :QuestDescription => "La competizione della Lega della Luce ha lanciato una sfida ufficiale all'Università. Scopri di cosa si tratta e vinci.",
    :RewardString => "nil"
  }

  Main_Scalata = {
    :ID => "25",
    :Name => "Sfida Ufficiale! La Scalata",
    :QuestGiver => "Organizzatori",
    :Stage1 => "Scala il Monte Ani.",
    :Location1 => "Monte Ani",
    :QuestDescription => "Nuova sfida ufficiale della Lega della Luce: scala il Monte Ani, recupera il premio e riportalo al Campo Base sano e salvo.",
    :RewardString => "nil"
  }

  Main_Taiani = {
    :ID => "26",
    :Name => "Aggiornamenti competitivologici",
    :QuestGiver => "Prof. Taiani",
    :Stage1 => "Raggiungi il Prof. Taiani.",
    :Location1 => "Percorso 1",
    :QuestDescription => "Il professor Taiani vuole saggiare i progressi di Batitiv ma pare porti anche brutte notizie...",
    :RewardString => "nil"
  }

  Main_Drago = {
    :ID => "27",
    :Name => "Fermento sull'Isola del Drago",
    :QuestGiver => "Prof. Taiani",
    :Stage1 => "Raggiungi l'Isola del Drago.",
    :Location1 => "Isola del Drago",
    :QuestDescription => "Il Prof. Taiani ha predisposto un traghetto al porto di Odeya City. Raggiungi l'Isola del Drago e ferma Prof. Sandman.",
    :RewardString => "nil"
  }

  Main_Stefano = {
    :ID => "28",
    :Name => "Un piano da sventare",
    :QuestGiver => "Prof. Taiani",
    :Stage1 => "Informa Stefano.",
    :Location1 => "Percorso 9",
    :Stage2 => "Informa Stefano.",
    :Location2 => "Monte Sjor",
    :Stage3 => "Sconfiggi Prof Sandman.",
    :Location3 => "Monte Sjor",
    :QuestDescription => "Il campione Stefano è stato avvistato! Raggiungilo ed informalo sui piani del Prof. Sandman.",
    :RewardString => "nil"
  }

  Side_PN = {
    :ID => "29",
    :Name => "Un Leggendario da restituire",
    :QuestGiver => "Allenatore Misterioso",
    :Stage1 => "Restituisci Rayquaza.",
    :Location1 => "???",
    :QuestDescription => "Un allenatore misterioso di ha prestato il suo Rayquaza per risolvere un'emergenza. Trovalo e riportaglielo.",
    :RewardString => "nil"
  }

  Main_Lega = {
    :ID => "30",
    :Name => "La Lega della Luce",
    :QuestGiver => "Organizzatori",
    :Stage1 => "Ottieni 7 Piastrine Gold.",
    :Location1 => "???",
    :Stage2 => "Raggiungi La Lega.",
    :Location2 => "Lega della Luce",
    :Stage3 => "Sconfiggi La Lega.",
    :Location3 => "Lega della Luce",
    :QuestDescription => "Sconfiggi la Lega più potente di tutte per diventare l'allenatore più forte del mondo e reclamare il ruolo di Campione.",
    :RewardString => "nil"
  }

  Side_Campioni = {
    :ID => "31",
    :Name => "Ospiti d'onore",
    :QuestGiver => "Prof. Taiani",
    :Stage1 => "Trova i Campioni.",
    :Location1 => "???",
    :QuestDescription => "Trova e sconfiggi i 6 Campioni, e Giovanni, che sono sparsi in luoghi isolati della regione di Rain'Bow.",
    :RewardString => "nil"
  }

end


#===========================================================================================================================

class Scene_DebugIntro
  def main
    Graphics.transition(0)
    sscene = PokemonLoad_Scene.new
    sscreen = PokemonLoadScreen.new(sscene)
    sscreen.pbStartLoadScreen
    Graphics.freeze
  end
end

def pbCallTitle
  return Scene_DebugIntro.new if $DEBUG
  # First parameter is an array of images in the Titles
  # directory without a file extension, to show before the
  # actual title screen.  Second parameter is the actual
  # title screen filename, also in Titles with no extension.
  return Scene_Intro.new(['intro1'], 'splash')
end

def mainFunction
  if $DEBUG
    pbCriticalCode { mainFunctionDebug }
  else
    mainFunctionDebug
  end
  return 1
end

def mainFunctionDebug
  begin
    getCurrentProcess = Win32API.new("kernel32.dll", "GetCurrentProcess", "", "l")
    setPriorityClass  = Win32API.new("kernel32.dll", "SetPriorityClass", %w(l i), "")
    setPriorityClass.call(getCurrentProcess.call(), 32768)   # "Above normal" priority class
    $data_animations    = pbLoadRxData("Data/Animations")
    $data_tilesets      = pbLoadRxData("Data/Tilesets")
    $data_common_events = pbLoadRxData("Data/CommonEvents")
    $data_system        = pbLoadRxData("Data/System")
    $game_system        = Game_System.new
    setScreenBorderName("border")   # Sets image file for the border
    Graphics.update
    Graphics.freeze
    $scene = pbCallTitle
    $scene.main until $scene.nil?
    Graphics.transition(20)
  rescue Hangup
    pbPrintException($!) if !$DEBUG
    pbEmergencySave
    raise
  end
end

loop do
  retval = mainFunction
  if retval == 0   # failed
    loop do
      Graphics.update
    end
  elsif retval == 1   # ended successfully
    break
  end
end

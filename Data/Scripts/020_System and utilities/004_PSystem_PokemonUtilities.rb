#===============================================================================
# Nicknaming and storing Pokémon
#===============================================================================
def pbBoxesFull?
  return ($Trainer.party.length==6 && $PokemonStorage.full?)
end

def pbNickname(pokemon)
  speciesname = PBSpecies.getName(pokemon.species)
  if pbConfirmMessage(_INTL("Would you like to give a nickname to {1}?",speciesname))
    helptext = _INTL("{1}'s nickname?",speciesname)
    newname = pbEnterPokemonName(helptext,0,PokeBattle_Pokemon::MAX_POKEMON_NAME_SIZE,"",pokemon)
    pokemon.name = newname if newname!=""
  end
end

def pbStorePokemon(pokemon)
  if pbBoxesFull?
    pbMessage(_INTL("There's no more room for Pokémon!\1"))
    pbMessage(_INTL("The Pokémon Boxes are full and can't accept any more!"))
    return
  end
  pokemon.pbRecordFirstMoves
  if $Trainer.party.length<6
    $Trainer.party[$Trainer.party.length] = pokemon
  else
    oldcurbox = $PokemonStorage.currentBox
    storedbox = $PokemonStorage.pbStoreCaught(pokemon)
    curboxname = $PokemonStorage[oldcurbox].name
    boxname = $PokemonStorage[storedbox].name
    creator = nil
    creator = pbGetStorageCreator if $PokemonGlobal.seenStorageCreator
    if storedbox!=oldcurbox
      if creator
        pbMessage(_INTL("Box \"{1}\" on {2}'s PC was full.\1",curboxname,creator))
      else
        pbMessage(_INTL("Box \"{1}\" on someone's PC was full.\1",curboxname))
      end
      pbMessage(_INTL("{1} was transferred to box \"{2}.\"",pokemon.name,boxname))
    else
      if creator
        pbMessage(_INTL("{1} was transferred to {2}'s PC.\1",pokemon.name,creator))
      else
        pbMessage(_INTL("{1} was transferred to someone's PC.\1",pokemon.name))
      end
      pbMessage(_INTL("It was stored in box \"{1}.\"",boxname))
    end
  end
end

def pbNicknameAndStore(pokemon)
  if pbBoxesFull?
    pbMessage(_INTL("There's no more room for Pokémon!\1"))
    pbMessage(_INTL("The Pokémon Boxes are full and can't accept any more!"))
    return
  end
  $Trainer.seen[pokemon.species]  = true
  $Trainer.owned[pokemon.species] = true
  pbNickname(pokemon)
  pbStorePokemon(pokemon)
end



#===============================================================================
# Giving Pokémon to the player (will send to storage if party is full)
#===============================================================================
def pbAddPokemon(pokemon,level=nil,seeform=true)
  return if !pokemon
  if pbBoxesFull?
    pbMessage(_INTL("There's no more room for Pokémon!\1"))
    pbMessage(_INTL("The Pokémon Boxes are full and can't accept any more!"))
    return false
  end
  pokemon = getID(PBSpecies,pokemon)
  if pokemon.is_a?(Integer) && level.is_a?(Integer)
    pokemon = pbNewPkmn(pokemon,level)
  end
  speciesname = PBSpecies.getName(pokemon.species)
  pbMessage(_INTL("{1} obtained {2}!\\me[Pkmn get]\\wtnp[80]\1",$Trainer.name,speciesname))
  pbNicknameAndStore(pokemon)
  pbSeenForm(pokemon) if seeform
  return true
end

def pbAddPokemonSilent(pokemon,level=nil,seeform=true)
  return false if !pokemon || pbBoxesFull?
  pokemon = getID(PBSpecies,pokemon)
  if pokemon.is_a?(Integer) && level.is_a?(Integer)
    pokemon = pbNewPkmn(pokemon,level)
  end
  $Trainer.seen[pokemon.species]  = true
  $Trainer.owned[pokemon.species] = true
  pbSeenForm(pokemon) if seeform
  pokemon.pbRecordFirstMoves
  if $Trainer.party.length<6
    $Trainer.party[$Trainer.party.length] = pokemon
  else
    $PokemonStorage.pbStoreCaught(pokemon)
  end
  return true
end



#===============================================================================
# Giving Pokémon/eggs to the player (can only add to party)
#===============================================================================
def pbAddToParty(pokemon,level=nil,seeform=true)
  return false if !pokemon || $Trainer.party.length>=6
  pokemon = getID(PBSpecies,pokemon)
  if pokemon.is_a?(Integer) && level.is_a?(Integer)
    pokemon = pbNewPkmn(pokemon,level)
  end
  speciesname = PBSpecies.getName(pokemon.species)
  pbMessage(_INTL("{1} obtained {2}!\\me[Pkmn get]\\wtnp[80]\1",$Trainer.name,speciesname))
  pbNicknameAndStore(pokemon)
  pbSeenForm(pokemon) if seeform
  return true
end

def pbAddToPartySilent(pokemon,level=nil,seeform=true)
  return false if !pokemon || $Trainer.party.length>=6
  pokemon = getID(PBSpecies,pokemon)
  if pokemon.is_a?(Integer) && level.is_a?(Integer)
    pokemon = pbNewPkmn(pokemon,level)
  end
  $Trainer.seen[pokemon.species]  = true
  $Trainer.owned[pokemon.species] = true
  pbSeenForm(pokemon) if seeform
  pokemon.pbRecordFirstMoves
  $Trainer.party[$Trainer.party.length] = pokemon
  return true
end

def pbAddForeignPokemon(pokemon,level=nil,ownerName=nil,nickname=nil,ownerGender=0,seeform=true)
  return false if !pokemon || $Trainer.party.length>=6
  pokemon = getID(PBSpecies,pokemon)
  if pokemon.is_a?(Integer) && level.is_a?(Integer)
    pokemon = pbNewPkmn(pokemon,level)
  end
  # Set original trainer to a foreign one (if ID isn't already foreign)
  if pokemon.trainerID==$Trainer.id
    pokemon.trainerID = $Trainer.getForeignID
    pokemon.ot        = ownerName if ownerName && ownerName!=""
    pokemon.otgender  = ownerGender
  end
  # Set nickname
  pokemon.name = nickname[0,PokeBattle_Pokemon::MAX_POKEMON_NAME_SIZE] if nickname && nickname!=""
  # Recalculate stats
  pokemon.calcStats
  if ownerName
    pbMessage(_INTL("\\me[Pkmn get]{1} received a Pokémon from {2}.\1",$Trainer.name,ownerName))
  else
    pbMessage(_INTL("\\me[Pkmn get]{1} received a Pokémon.\1",$Trainer.name))
  end
  pbStorePokemon(pokemon)
  $Trainer.seen[pokemon.species]  = true
  $Trainer.owned[pokemon.species] = true
  pbSeenForm(pokemon) if seeform
  return true
end

def pbGenerateEgg(pokemon,text="")
  return false if !pokemon || $Trainer.party.length>=6
  pokemon = getID(PBSpecies,pokemon)
  if pokemon.is_a?(Integer)
    pokemon = pbNewPkmn(pokemon,EGG_LEVEL)
  end
  # Get egg steps
  eggSteps = pbGetSpeciesData(pokemon.species,pokemon.form,SpeciesStepsToHatch)
  # Set egg's details
  pokemon.name       = _INTL("Egg")
  pokemon.eggsteps   = eggSteps
  pokemon.obtainText = text
  pokemon.calcStats
  # Add egg to party
  $Trainer.party[$Trainer.party.length] = pokemon
  return true
end
alias pbAddEgg pbGenerateEgg
alias pbGenEgg pbGenerateEgg



#===============================================================================
# Removing Pokémon from the party (fails if trying to remove last able Pokémon)
#===============================================================================
def pbRemovePokemonAt(index)
  return false if index<0 || index>=$Trainer.party.length
  haveAble = false
  for i in 0...$Trainer.party.length
    next if i==index
    haveAble = true if $Trainer.party[i].hp>0 && !$Trainer.party[i].egg?
  end
  return false if !haveAble
  $Trainer.party.delete_at(index)
  return true
end



#===============================================================================
# Recording Pokémon forms as seen
#===============================================================================
def pbSeenForm(pkmn,gender=0,form=0)
  $Trainer.formseen     = [] if !$Trainer.formseen
  $Trainer.formlastseen = [] if !$Trainer.formlastseen
  if pkmn.is_a?(PokeBattle_Pokemon)
    gender  = pkmn.gender
    form    = (pkmn.form rescue 0)
    species = pkmn.species
  else
    species = getID(PBSpecies,pkmn)
  end
  return if !species || species<=0
  fSpecies = pbGetFSpeciesFromForm(species,form)
  species, form = pbGetSpeciesFromFSpecies(fSpecies)
  gender = 0 if gender>1
  dexForm = pbGetSpeciesData(species,form,SpeciesPokedexForm)
  form = dexForm if dexForm>0
  fSpecies = pbGetFSpeciesFromForm(species,form)
  formName = pbGetMessage(MessageTypes::FormNames,fSpecies)
  form = 0 if !formName || formName==""
  $Trainer.formseen[species] = [[],[]] if !$Trainer.formseen[species]
  $Trainer.formseen[species][gender][form] = true
  $Trainer.formlastseen[species] = [] if !$Trainer.formlastseen[species]
  $Trainer.formlastseen[species] = [gender,form] if $Trainer.formlastseen[species]==[]
end

def pbUpdateLastSeenForm(pkmn)
  $Trainer.formlastseen = [] if !$Trainer.formlastseen
  form = (pkmn.form rescue 0)
  dexForm = pbGetSpeciesData(pkmn.species,pkmn.form,SpeciesPokedexForm)
  form = dexForm if dexForm>0
  formName = pbGetMessage(MessageTypes::FormNames,pkmn.fSpecies)
  form = 0 if !formName || formName==""
  $Trainer.formlastseen[pkmn.species] = [] if !$Trainer.formlastseen[pkmn.species]
  $Trainer.formlastseen[pkmn.species] = [pkmn.gender,form]
end



#===============================================================================
# Choose a Pokémon in the party
#===============================================================================
# Choose a Pokémon/egg from the party.
# Stores result in variable _variableNumber_ and the chosen Pokémon's name in
# variable _nameVarNumber_; result is -1 if no Pokémon was chosen
def pbChoosePokemon(variableNumber,nameVarNumber,ableProc=nil,allowIneligible=false)
  chosen = 0
  pbFadeOutIn {
    scene = PokemonParty_Scene.new
    screen = PokemonPartyScreen.new(scene,$Trainer.party)
    if ableProc
      chosen=screen.pbChooseAblePokemon(ableProc,allowIneligible)
    else
      screen.pbStartScene(_INTL("Choose a Pokémon."),false)
      chosen = screen.pbChoosePokemon
      screen.pbEndScene
    end
  }
  pbSet(variableNumber,chosen)
  if chosen>=0
    pbSet(nameVarNumber,$Trainer.party[chosen].name)
  else
    pbSet(nameVarNumber,"")
  end
end

def pbChooseNonEggPokemon(variableNumber,nameVarNumber)
  pbChoosePokemon(variableNumber,nameVarNumber,proc { |pkmn| !pkmn.egg? })
end

def pbChoose0EvsPokemon(variableNumber,nameVarNumber)
  pbChoosePokemon(variableNumber,nameVarNumber,proc { |pkmn| pkmn.ev[0] + pkmn.ev[1] + pbGetPokemon(1).ev[2] + pkmn.ev[3] + pkmn.ev[4] + pkmn.ev[5] == 0 })
end

def pbChooseAblePokemon(variableNumber,nameVarNumber)
  pbChoosePokemon(variableNumber,nameVarNumber,proc { |pkmn| !pkmn.egg? && pkmn.hp>0 })
end

# Same as pbChoosePokemon, but prevents choosing an egg or a Shadow Pokémon.
def pbChooseTradablePokemon(variableNumber,nameVarNumber,ableProc=nil,allowIneligible=false)
  chosen = 0
  pbFadeOutIn {
    scene = PokemonParty_Scene.new
    screen = PokemonPartyScreen.new(scene,$Trainer.party)
    if ableProc
      chosen=screen.pbChooseTradablePokemon(ableProc,allowIneligible)
    else
      screen.pbStartScene(_INTL("Choose a Pokémon."),false)
      chosen = screen.pbChoosePokemon
      screen.pbEndScene
    end
  }
  pbSet(variableNumber,chosen)
  if chosen>=0
    pbSet(nameVarNumber,$Trainer.party[chosen].name)
  else
    pbSet(nameVarNumber,"")
  end
end


def pbChoosePokemonForTrade(variableNumber,nameVarNumber,wanted)
  wanted = getID(PBSpecies,wanted)
  pbChooseTradablePokemon(variableNumber,nameVarNumber,proc { |pkmn|
    next pkmn.species==wanted
  })
end



#===============================================================================
# Analyse Pokémon in the party
#===============================================================================
# Returns the first unfainted, non-egg Pokémon in the player's party.
def pbFirstAblePokemon(variableNumber)
  for i in 0...$Trainer.party.length
    p = $Trainer.party[i]
    if p && !p.egg? && p.hp>0
      pbSet(variableNumber,i)
      return $Trainer.party[i]
    end
  end
  pbSet(variableNumber,-1)
  return nil
end

# Checks whether the player would still have an unfainted Pokémon if the
# Pokémon given by _pokemonIndex_ were removed from the party.
def pbCheckAble(pokemonIndex)
  for i in 0...$Trainer.party.length
    next if i==pokemonIndex
    p = $Trainer.party[i]
    return true if p && !p.egg? && p.hp>0
  end
  return false
end

# Returns true if there are no usable Pokémon in the player's party.
def pbAllFainted
  return $Trainer.ablePokemonCount==0
end

# Returns true if there is a Pokémon of the given species in the player's party.
# You may also specify a particular form it should be.
def pbHasSpecies?(species,form=-1)
  species = getID(PBSpecies,species)
  for pokemon in $Trainer.pokemonParty
    return true if pokemon.species==species && (form<0 || form==pokemon.form)
  end
  return false
end

# Returns true if there is a fatefully met Pokémon of the given species in the
# player's party.
def pbHasFatefulSpecies?(species)
  species = getID(PBSpecies,species)
  for pokemon in $Trainer.pokemonParty
    return true if pokemon.species==species && pokemon.obtainMode==4
  end
  return false
end

# Returns true if there is a Pokémon with the given type in the player's party.
def pbHasType?(type)
  type = getID(PBTypes,type)
  for pokemon in $Trainer.pokemonParty
    return true if pokemon.hasType?(type)
  end
  return false
end

# Checks whether any Pokémon in the party knows the given move, and returns
# the first Pokémon it finds with that move, or nil if no Pokémon has that move.
def pbCheckMove(move)
  move = getID(PBMoves,move)
  return nil if !move || move<=0
  for i in $Trainer.pokemonParty
    for j in i.moves
      return i if j.id==move
    end
  end
  return nil
end



#===============================================================================
# Fully heal all Pokémon in the party
#===============================================================================
def pbHealAll
  $Trainer.party.each { |pkmn| pkmn.heal }
end



#===============================================================================
# Return a level value based on Pokémon in a party
#===============================================================================
def pbBalancedLevel(party)
  return 1 if party.length==0
  # Calculate the mean of all levels
  sum = 0
  party.each { |p| sum += p.level }
  return 1 if sum==0
  mLevel = PBExperience.maxLevel
  average = sum.to_f/party.length.to_f
  # Calculate the standard deviation
  varianceTimesN = 0
  for i in 0...party.length
    deviation = party[i].level-average
    varianceTimesN += deviation*deviation
  end
  # NOTE: This is the "population" standard deviation calculation, since no
  # sample is being taken.
  stdev = Math.sqrt(varianceTimesN/party.length)
  mean = 0
  weights = []
  # Skew weights according to standard deviation
  for i in 0...party.length
    weight = party[i].level.to_f/sum.to_f
    if weight<0.5
      weight -= (stdev/mLevel.to_f)
      weight = 0.001 if weight<=0.001
    else
      weight += (stdev/mLevel.to_f)
      weight = 0.999 if weight>=0.999
    end
    weights.push(weight)
  end
  weightSum = 0
  weights.each { |w| weightSum += w }
  # Calculate the weighted mean, assigning each weight to each level's
  # contribution to the sum
  for i in 0...party.length
    mean += party[i].level*weights[i]
  end
  mean /= weightSum
  # Round to nearest number
  mean = mean.round
  # Adjust level to minimum
  mean = 1 if mean<1
  # Add 2 to the mean to challenge the player
  mean += 2
  # Adjust level to maximum
  mean = mLevel if mean>mLevel
  return mean
end



#===============================================================================
# Calculates a Pokémon's size (in millimeters)
#===============================================================================
def pbSize(pkmn)
  baseheight = pbGetSpeciesData(pkmn.species,pkmn.form,SpeciesHeight)
  hpiv = pkmn.iv[0]&15
  ativ = pkmn.iv[1]&15
  dfiv = pkmn.iv[2]&15
  spiv = pkmn.iv[3]&15
  saiv = pkmn.iv[4]&15
  sdiv = pkmn.iv[5]&15
  m = pkmn.personalID&0xFF
  n = (pkmn.personalID>>8)&0xFF
  s = (((ativ^dfiv)*hpiv)^m)*256+(((saiv^sdiv)*spiv)^n)
  xyz = []
  if s<10;       xyz = [ 290,   1,     0]
  elsif s<110;   xyz = [ 300,   1,    10]
  elsif s<310;   xyz = [ 400,   2,   110]
  elsif s<710;   xyz = [ 500,   4,   310]
  elsif s<2710;  xyz = [ 600,  20,   710]
  elsif s<7710;  xyz = [ 700,  50,  2710]
  elsif s<17710; xyz = [ 800, 100,  7710]
  elsif s<32710; xyz = [ 900, 150, 17710]
  elsif s<47710; xyz = [1000, 150, 32710]
  elsif s<57710; xyz = [1100, 100, 47710]
  elsif s<62710; xyz = [1200,  50, 57710]
  elsif s<64710; xyz = [1300,  20, 62710]
  elsif s<65210; xyz = [1400,   5, 64710]
  elsif s<65410; xyz = [1500,   2, 65210]
  else;          xyz = [1700,   1, 65510]
  end
  return (((s-xyz[2])/xyz[1]+xyz[0]).floor*baseheight/10).floor
end



#===============================================================================
# Returns true if the given species can be legitimately obtained as an egg
#===============================================================================
def pbHasEgg?(species)
  species = getID(PBSpecies,species)
  return false if !species
  # species may be unbreedable, so check its evolution's compatibilities
  evoSpecies = pbGetEvolvedFormData(species,true)
  compatSpecies = (evoSpecies && evoSpecies[0]) ? evoSpecies[0][2] : species
  compat = pbGetSpeciesData(compatSpecies,0,SpeciesCompatibility)
  compat = [compat] if !compat.is_a?(Array)
  return false if compat.include?(getConst(PBEggGroups,:Undiscovered))
  return false if compat.include?(getConst(PBEggGroups,:Ditto))
  baby = pbGetBabySpecies(species)
  return true if species==baby   # Is a basic species
  baby = pbGetBabySpecies(species,0,0)
  return true if species==baby   # Is an egg species without incense
  return false
end

#===============================================================================
# Rental Team Utilities
#===============================================================================
#Saves the team for rental
def pbSaveTeam
  $game_variables[99]= $Trainer.party
  $Trainer.party = []
end

#Choose from list
def pbChooseSpeciesOrdered(default=1, rarity=1)
  rarity_1 = [
    getConst(PBSpecies,:TENTACRUEL), 
    getConst(PBSpecies,:VICTREEBEL), 
    getConst(PBSpecies,:SANDSLASH), 
    getConst(PBSpecies,:DELIBIRD),
    getConst(PBSpecies,:STANTLER),
    getConst(PBSpecies,:ARIADOS),
    getConst(PBSpecies,:CLAYDOL),
    getConst(PBSpecies,:GLALIE),
    getConst(PBSpecies,:RELICANTH),
    getConst(PBSpecies,:LOPUNNY),
    getConst(PBSpecies,:CHATOT),
    getConst(PBSpecies,:CARNIVINE),
    getConst(PBSpecies,:LIEPARD),
    getConst(PBSpecies,:MARACTUS),
    getConst(PBSpecies,:SIMISEAR)
  ]

  rarity_2 = [
  getConst(PBSpecies,:POLIWRATH), 
  getConst(PBSpecies,:HYPNO), 
  getConst(PBSpecies,:PRIMEAPE), 
  getConst(PBSpecies,:SKARMORY),
  getConst(PBSpecies,:HOUNDOOM),
  getConst(PBSpecies,:UMBREON),
  getConst(PBSpecies,:HARIYAMA),
  getConst(PBSpecies,:WALREIN),
  getConst(PBSpecies,:WAILORD),
  getConst(PBSpecies,:LEAFEON),
  getConst(PBSpecies,:TOXICROAK),
  getConst(PBSpecies,:LUXRAY),
  getConst(PBSpecies,:CRUSTLE),
  getConst(PBSpecies,:EXCADRILL),
  getConst(PBSpecies,:UNFEZANT)
  ]

  rarity_3 = [
    getConst(PBSpecies,:DRAGONITE), 
    getConst(PBSpecies,:ALAKAZAM), 
    getConst(PBSpecies,:MACHAMP), 
    getConst(PBSpecies,:AMPHAROS),
    getConst(PBSpecies,:BLISSEY),
    getConst(PBSpecies,:TYRANITAR),
    getConst(PBSpecies,:SALAMENCE),
    getConst(PBSpecies,:METAGROSS),
    getConst(PBSpecies,:AGGRON),
    getConst(PBSpecies,:GALLADE),
    getConst(PBSpecies,:MAGMORTAR),
    getConst(PBSpecies,:LUCARIO),
    getConst(PBSpecies,:HYDREGON),
    getConst(PBSpecies,:VOLCARONA),
    getConst(PBSpecies,:BRAVIARY)
    ]

  commands = []
  pkmn_list = []

  list = rarity_1 if rarity == 1
  list = rarity_2 if rarity == 2
  list = rarity_3 if rarity == 3

  list = list.sort_by { rand }
  list = list[0..2]

  list.each do |i|
    cname = getConstantName(PBSpecies,i) rescue nil
    commands.push([i,PBSpecies.getName(i)]) if cname
  end
  return pbChooseList(commands,default,0,-1)
end

#Rental Pokemon for Single 
def pbRentalSpecies(rarity)  
    species=pbChooseSpeciesOrdered(1, rarity)
    return false if species == 0
    level=100
    pbAddPokemonBattler(getRandomPokemon(whitelist=[species], nil, level, nil, nil))
    speciesname = PBSpecies.getName(species)
    pbMessage(_INTL("{1} obtained {2}!\\se[Battle recall]\\wtnp[20]\1",$Trainer.name,speciesname))
    return true
end


#Returns Party that was stored in variable
def pbRentReturn
  $Trainer.party = $game_variables[99]
  Kernel.pbMessage(_INTL("Ti è stata restituità la tua squadra."))
end

#Pokémon randomizer
#============================================================
#Random_Pokemon script by leilou
#
#This script is ment to help to create a random Pokémon in Pokémon Essentials
#
#Pokémon Essentials is created by Poccil, based on Flameguru's 
#Pokémon Starter Kit and managed and updated by Maruno
#
#I don't claim this script to be perfect. 
#Please report bugs at the resources thread on Relic Castle.
#=============================================================
#
#functions:
#
# getRandomPokemon(whitelist,blacklist,level,movewhitelist,moveblacklist)
#   Summary:
#	 Returns a random Pokémon with random moves and level(optional)
#   Arguments:
#	 whitelist:
#	   An array of Pokémon or nil. 
#	   If an Array is given the script will choose a Pokémon out of the array.
#	   If nil is given the script will choose out of all Pokémon.
#	   Default: nil
#	 blacklist:
#	   An array of Pokémon or nil. 
#	   If an Array is given the script will not choose a Pokémon out of the array.
#	   If nil is given the script will not blacklist any Pokémon.
#	   Default: nil
#	 level:
#	   An Integer or nil
#	   If an Integer is given the Pokémon will have that level.
#	   If nil is given the Pokémon will have a random level between 0 and 100.
#	   Default: nil
#	 movewhitelist:
#	   An array of Moves, false or nil. 
#	   If an Array is given the Pokémon will only have moves out of this Array.
#	   If false is given the Pokémon will have it's natural moves(the ones a
#		 wild Pokémon on that level would have).
#	   If nil is given the script will choose out of all Moves the Pokémon can
#		 learn by leveling up or tm.
#	   Default: nil
#	 moveblacklist:
#	   An array of Moves or nil. 
#	   If an Array is given the Pokémon will not have a Moves out of the array.
#	   If nil is given the script will not blacklist any Moves.
#	   Default: nil
#   return value:
#	 The generated Pokémon of the type PokeBattle_Pokemon
#
# addPokemon(pokemon)
#   Summary:
#	 Places the given Pokémon in the players team/storage. 
#	 It does the same as pbAddPokemon. The difference it that it takes
#	 a PokeBattle_Pokemon as argument which is returned by getRandomPokemon.
#   Arguments:
#	 pokemon:
#	   A PokeBattle_Pokemon object
#	   This is the Pokémon to be added.
#   return value:
#	   none
#
# getAllPokemonList
#   Summary:
#	 Returns a list of all Pokémon defined in the PBS file pokemon.txt
#	 You may want to use this method to generate a whitelist with all Pokémon.
#   Arguments: 
#	 none
#   return value:
#	 A list of Integers that represent the dex number of all Pokémon.
#
# filterUnevolved(pokemonList)
#   Summary:
#	 Returns a list of all unevolved Pokeémon in pokemonList.
#   Arguments:
#	 pokemonList:
#	   An array of Integer or PBSpecies
#	   An array of Pokémon. This is the array to be filtered.
#   return value:
#	 A list of Integers that represent the dex number of the unevolved Pokémon.
#
# filterType(pokemonList, type1, type2)
#   Summary:
#	 Returns a list of all Pokémon in pokemonList of the given type(s).
#   Arguments:
#	 pokemonList:
#	   An array of Integer or PBSpecies
#	   An array of Pokémon. This is the array to be filtered.
#	 type1:
#	   PBTypes
#	   The type to filter for.
#	 type2:
#	   PBTypes, nil or false
#		 When a type is given only Pokémon with the two given types are returned.
#		 When nil is given any Pokémon with type1 as type are returned.
#		 When false is fiven only Pokémon that are only type1 are returned.
#   return value:
#	 An array of Integers that represent the dex number of the Pokémon of the
#	 given type(s).
#
# getAllPossibleMoves(pokemon)
#   Summary:
#	 This method returns a list of the ids of all natural and tm moves the
#	 Pokémon can learn without taking level into account.
#   Arguments:
#	 pokemon:
#	   PokeBattle_Pokemon
#	   The Pokémon in question.
#   return value:
#	 An array of Integers representing the ids of all moves that can be learned
#	 by the Pokémon.
#
#=============================================================
 
def getRandomPokemon(whitelist = nil, blacklist = nil, level = nil, 
  movewhitelist = nil, moveblacklist = nil)
randomMoves = true
if movewhitelist == false
randomMoves = false
end
#make sure whitelist and blacklist are in the right format
if whitelist.is_a?(Array)
for i in 0 ... whitelist.length
  if whitelist[i].is_a?(String) || whitelist[i].is_a?(Symbol)
  whitelist[i]=getID(PBSpecies,whitelist[i])
  end
  if whitelist[i].is_a?(Integer)
  const = getConstantName(PBSpecies,whitelist[i]) rescue whitelist[i] = nil
  if !hasConst?(PBSpecies,const) #the pokemon doesn't exist
    whitelist[i] = nil
  end
  else
  whitelist[i] = nil
  end
end
whitelist.compact!
if whitelist.length == 0
  return nil #empty whitelist
end
else
whitelist = nil
end

if !whitelist #no whitelist => choose from all pokemon
whitelist = getAllPokemonList
end 

if blacklist.is_a?(Array)
for i in 0 ... blacklist.length
  if blacklist[i].is_a?(String) || blacklist[i].is_a?(Symbol)
  blacklist[i]=getID(PBSpecies,blacklist[i])
  end
  if blacklist[i].is_a?(Integer)
  const = getConstantName(PBSpecies,blacklist[i]) rescue blacklist[i] = nil
  if !hasConst?(PBSpecies,const) #the pokemon doesn't exist
    blacklist[i] = nil
  end
  else
  blacklist[i] = nil
  end
end
blacklist.uniq! #remove all duplicates
blacklist.compact!
if blacklist.length == 0
  blacklist = nil
end
else
blacklist = nil
end

#sort blacklist out of whitelist
if blacklist
for i in 0 ... whitelist.length
  if blacklist.include?(whitelist[i])
  whitelist[i] = nil
  end
end
whitelist.compact!
if whitelist.length == 0
  return nil #all pkmn of whitelist are in blacklist
end
end
 
id = nil
#choose pokemon species
randNum = rand(whitelist.length-1)
id = whitelist[randNum]


#choose level if none is given
if !(level && level.is_a?(Integer))
level = rand(99) + 1
end
#create a pokemon with player as trainer and without moves
pokemon=PokeBattle_Pokemon.new(id,level,$Trainer,false)

#randomize moves(all natural and tm moves)
if randomMoves
#format move whitelist
if movewhitelist && movewhitelist.is_a?(Array)
  for i in 0 ... movewhitelist.length
  if movewhitelist[i].is_a?(String) || movewhitelist[i].is_a?(Symbol)
    movewhitelist[i]=getID(PBMoves,movewhitelist[i])
  end
  if whitelist[i].is_a?(Integer)
    const = getConstantName(PBMoves,movewhitelist[i]) rescue movewhitelist[i] = nil
    if !hasConst?(PBMoves,const) #the pokemon doesn't exist
    movewhitelist[i] = nil
    end
  else
    movewhitelist[i] = nil
  end
  end
  movewhitelist.compact!
else
  movewhitelist = nil
end

#format move blacklist
if moveblacklist && moveblacklist.is_a?(Array)
  for i in 0 ... moveblacklist.length
  if moveblacklist[i].is_a?(String) || moveblacklist[i].is_a?(Symbol)
    moveblacklist[i]=getID(PBMoves,moveblacklist[i])
  end
  if moveblacklist[i].is_a?(Integer)
    const = getConstantName(PBMoves,moveblacklist[i]) rescue moveblacklist[i] = nil
    if !hasConst?(PBMoves,const) #the pokemon doesn't exist
    moveblacklist[i] = nil
    end
  else
    moveblacklist[i] = nil
  end
  end
  moveblacklist.compact!
else
  moveblacklist = nil
end

#if there is no whitelist make all learnable attacks the whitelist
if !movewhitelist
  movewhitelist = getAllPossibleMoves(pokemon)
end

#sort out blacklist moves of whitelist
if moveblacklist && movewhitelist
  for i in 0 ... movewhitelist.length
  if moveblacklist.includes?(movewhitelist[i])
    movewhitelist[i] = nil
  end
  end
  movewhitelist.compact!
end
pokemon.moves = [] #delete all moves

4.times do
  if movewhitelist.length == 0
  break
  end
  randNum = rand(movewhitelist.length-1)
  pokemon.moves.push(PBMove.new(movewhitelist[randNum]))
  movewhitelist.delete_at(randNum)
end
else #pokemon learns the moves it would naturally have on this level
pokemon.resetMoves
end

return pokemon
end

def getAllPossibleMoves(pokemon)
moves=[] #all learnable moves
pbEachNaturalMove(pokemon){|move,level|
 moves.push(move) if !moves.include?(move)
}
data = load_data("Data/tm.dat")
for i in 0 ... data.length
if pokemon.compatibleWithMove?(i)
  moves.push(i) if !moves.include?(i)
end
end
return moves
end

def pbAddPokemonBattler(pokemon)
if pbBoxesFull?
Kernel.pbMessage(_INTL("There's no more room for Pokémon!\1"))
Kernel.pbMessage(_INTL("The Pokémon Boxes are full and can't accept any more!"))
return false
end
speciesname=PBSpecies.getName(pokemon.species)
if $Trainer.party.length<6
  $Trainer.party[$Trainer.party.length] = pokemon
else
  $PokemonStorage.pbStoreCaught(pokemon)
end
end

#returns only the unevolved pokemon in the list
def filterUnevolved(pokemonList)
#break if wrong input
if !(pokemonList && pokemonList.is_a?(Array))
return
end

for i in 0 ... pokemonList.length
#make sure everything is formatted the right way
if pokemonList[i].is_a?(String) || pokemonList[i].is_a?(Symbol)
  pokemonList[i]=getID(PBSpecies,pokemonList[i])
end
if pokemonList[i].is_a?(Integer)
  const = getConstantName(PBSpecies,pokemonList[i]) rescue pokemonList[i] = nil
  if !hasConst?(PBSpecies,const) #the pokemon doesn't exist
  pokemonList[i] = nil
  end
  #check if pokemon has a prevolution
  if pokemonList[i] != pbGetPreviousForm(pokemonList[i])
  pokemonList[i] = nil
  end
else
  pokemonList[i] = nil
end
end
pokemonList.compact!
return pokemonList
end

def filterType(pokemonList, type1, type2=nil)
#break if wrong input
if !(pokemonList && pokemonList.is_a?(Array))
return
end

dexdata=pbOpenDexData

for i in 0 ... pokemonList.length
#make sure everything is formatted the right way
if pokemonList[i].is_a?(String) || pokemonList[i].is_a?(Symbol)
  pokemonList[i]=getID(PBSpecies,pokemonList[i])
end
if pokemonList[i].is_a?(Integer)
  const = getConstantName(PBSpecies,pokemonList[i]) rescue pokemonList[i] = nil
  if !hasConst?(PBSpecies,const) #the pokemon doesn't exist
  pokemonList[i] = nil
  end
  #check if pokemon has the requested types
  pbDexDataOffset(dexdata,pokemonList[i],8)
  ptype1=dexdata.fgetb
  pbDexDataOffset(dexdata,pokemonList[i],9)
  ptype2=dexdata.fgetb
  if !(type1==ptype1||type1==ptype2)
  pokemonList[i] = nil
  next
  elsif type2 && !(type2==ptype1||type2==ptype2)
  pokemonList[i] = nil
  next
  elsif (type2 == false) && (ptype1 != ptype2)
  pokemonList[i] = nil
  next
  end
else
  pokemonList[i] = nil
end
end
pokemonList.compact!
dexdata.close
return pokemonList
end

def getAllPokemonList
pokemonList = []
for i in 0..PBSpecies.maxValue
for c in PBSpecies.constants
  if PBSpecies.const_get(c.to_sym)==i
  pokemonList.push(i)
  end
end
end
return pokemonList
end

//
//  GameScene.swift
//  DuckGolfInTheMediterranean
//
//  Created by Richie Gurgul on 9/16/16.
//  Copyright (c) 2016 Richie Gurgul. All rights reserved.
//

/* RICHIE'S ANSWERS
 1. What were your greatest strengths in creating this app?
 
 
 2. What are some weaknesses that you should work on for future projects similar to this?
 unfamiliarity with the concepts (SpriteKit)
 
 3. What did you learn specifically about spriteKit from this project?
 some bits and pieces of how to use SpriteKit
 
 4. What were your major contributions to the app?
 I "drove the bus" and did most of the programming
 
 5. What were your partner's major contributions to the app?
 He created all of the graphics, came up with the concept, and created the graphics
 
 6. How many hours did you honestly put into this project (we had roughly 12 in class hours)?
 12 (10 in class, 2 out of class)
 
 7. Where the videos helpful and what other ways would you prefer to learn about the content of spriteKit?
 I did not use any of the videos, mostly because they were just reviews of the aspects of CrashyPlane. I would prefer to learn in mini-project styles like last year. Introducing concepts is easier when done first in practice, then put to the test for mastery.
 
 */

/* PETER'S ANSWERS
 1.What were your greatest strengths in creating this app?
 problem solving skills
 
 2. What are some weaknesses that you should work on for future projects similar to this?
 getting distracted
 
 3. What did you learn specifically about spriteKit from this project?
 that we can add physics.
 
 4. What were your major contributions to the app?
 I came up with concept and made art and helped by "navigating the bus"
 
 5. What were your partner's major contributions to the app?
 he "drove the bus" and i "navigated"
 
 6. How many hours did you honestly put into this project (we had roughly 12 in class hours)?
 12
 
 7. Where the videos helpful and what other ways would you prefer to learn about the content of spriteKit?
 i didn't use the videos, hackwiches and challenges would have been nice.
 */

import SpriteKit
import GameKit

class GameScene: SKScene
{
    //Main Nodes
    var enemies = [SKSpriteNode]()
    var player: SKSpriteNode!
    
    //Nodes for the white line when you drag
    var dragNode: SKShapeNode!
    var dragPath: CGMutablePath!
    
    //Location of where you drag your touch to
    var dragLocation: CGPoint!
    
    //How far left/right and up/down you dragged in relation to 0,0 in the middle of the screen
    var horizontalMagnitude: CGFloat!
    var verticalMagnitude: CGFloat!
    
    //Count how many tugboats you have destroyed.
    var scoreLabel: SKLabelNode!
    var score = 0
    {
        didSet
        {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    //Display how much life you have left.
    //You lose 10 per ship that hits you
    //You lose 5 per self-damaging shot
    var lifeLabel: SKLabelNode!
    var life = 100
    {
        didSet
        {
            lifeLabel.text = "Life: \(life)%"
        }
    }
    
    //Count the number of active shots (max = 2)
    var numBullets = 0
    
    //Variable amount of delay in between boat spawns
    var spawnDelay = 4.0
    
    override func didMove(to view: SKView)
    {
        //Center the scene in the middle (0,0)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        //Create all the major nodes
        createPlayer()
        createBackground()
        createDragNode()
        createLabels()
        
        //Start spawning the tugboats
        spawnLilToots()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        //Get the location of the touch
        let touch: UITouch = touches.first! as UITouch
        let temp = touch.location(in: view)
        
        //Approximate the center coordinates
        let width = frame.width / 5
        let height = frame.height / 2
        
        //Set dragLocation to the inverted location of the tap
        dragLocation = CGPoint(x: -temp.x + width, y: temp.y - height)
        
        //Set the magnitudes to the displacement in the x and y directions
        horizontalMagnitude = dragLocation.x
        verticalMagnitude = dragLocation.y
        
        //Remove the drag line once you have stopped dragging
        dragNode.removeFromParent()
        
        //Create the bullet, which accesses the magnitudes to shoot it in a direction
        createBullet()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        //Get the location of the touch
        let touch: UITouch = touches.first! as UITouch
        let temp = touch.location(in: view)
        
        //Approximate the center coordinates
        let width = frame.width / 5
        let height = frame.height / 2
        
        //Set dragLocation to the inverted location of the tap
        dragLocation = CGPoint(x: -temp.x + width, y: temp.y - height)
        
        //Draw the line from the middle to the inverted point
        drawDragLine(point: dragLocation)
    }
    
    func createPlayer()
    {
        //Create an array to store the textures of the animation
        var textures = [SKTexture]()
        
        //Programmatically add all 4 images into the array
        for i in 1...4
        {
            textures.append(SKTexture(imageNamed: "heli-\(i)"))
        }
        
        //Create the node with the first texture
        player = SKSpriteNode(texture: textures[0])
        
        //Create and run the animation
        let animation = SKAction.animate(with: textures, timePerFrame: 1/30)
        let animateForever = SKAction.repeatForever(animation)
        player.run(animateForever)
        
        //Center the player in the middle
        player.position = CGPoint.zero
        player.zPosition = 100
        
        addChild(player)
    }
    
    func createBullet()
    {
        //Check if the player has exceeded the maximum number of bullets
        if numBullets > 2
        {
            return
        }
        
        //Create a simple black circular node
        let bullet = SKShapeNode(circleOfRadius: 5)
        bullet.fillColor = UIColor.black
        bullet.strokeColor = UIColor.black
        bullet.position = CGPoint.zero
        bullet.zPosition = 30
        
        //Move it to the inverted location in a random amount of time
        let randomDelay = Double(GKRandomDistribution(lowestValue: 5, highestValue: 30).nextInt() / 10)
        let move = SKAction.move(to: dragLocation, duration: randomDelay)
        let collisionSimulation = SKAction.run
        {
            //Check if the bullet is in range of any enemies, or the player
            self.checkYoSelfBeforeYouRekYourself(bullet: bullet)
        }
        let sequence = SKAction.sequence([move, collisionSimulation, SKAction.removeFromParent()])
        bullet.run(sequence)
        
        addChild(bullet)
        
        //Count the number of active bullets
        numBullets += 1
    }
    
    func createEnemy()
    {
        //Randomly generate X and Y coordinates
        let randomX = CGFloat(GKRandomDistribution(lowestValue: Int(frame.minX), highestValue: Int(frame.maxX)).nextInt())
        let randomY = CGFloat(GKRandomDistribution(lowestValue: Int(frame.minY), highestValue: Int(frame.maxY)).nextInt())
        
        var spawn: CGPoint!
        //Randomly decide where to spawn the tugboat
        switch GKRandomDistribution(lowestValue: 1, highestValue: 4).nextInt()
        {
        case 1: //Random X coordinate along the top edge
            spawn = CGPoint(x: randomX, y: frame.maxY)
            break
        case 2: //Random X coordinate along the bottom edge
            spawn = CGPoint(x: randomX, y: frame.minY)
            break
        case 3: //Random Y coordinate along the right edge
            spawn = CGPoint(x: frame.maxX, y: randomY)
            break
        case 4: //Random Y coordinate along the left edge
            spawn = CGPoint(x: frame.minX, y: randomY)
            break
        default: //This should never be called, but defaults are required
            print("oh no")
        }
        
        //Create an array to store the textures of the animation
        var textures = [SKTexture]()
        
        //Programmatically add all 6 images into the array
        for i in 1...6
        {
            textures.append(SKTexture(imageNamed: "tugboat-\(i)"))
        }
        
        //Create the node with the first texture
        let enemy = SKSpriteNode(texture: textures[0])
        
        //Create and run the animation
        let animation = SKAction.animate(with: textures, timePerFrame: 1/12)
        let animateForever = SKAction.repeatForever(animation)
        enemy.run(animateForever)

        //Set the enemy's position to the randomly determined spawn point
        enemy.position = spawn
        enemy.zPosition = 20
        
        //Add the enemy to the enemy array to be checked upon later
        enemies.append(enemy)
        
        //Move it to the player's location in a random amount of time
        let randomDelay = Double(GKRandomDistribution(lowestValue: 12, highestValue: 18).nextInt())
        let move = SKAction.move(to: CGPoint.zero, duration: randomDelay)
        let collisionSimulation = SKAction.run
        {
            //If an enemy has not been removed by the time it reaches this action, then we will damage the player
            self.lilTootTouchedTheButt()
        }
        let sequence = SKAction.sequence([move, collisionSimulation, SKAction.removeFromParent()])
        enemy.run(sequence)
        
        addChild(enemy)
    }
    
    func createDragNode()
    {
        //Create the path that the node will follow, which will simply be a line between 2 points
        dragPath = CGMutablePath()
        dragPath.move(to: CGPoint.zero)
        
        //Create a shape node, which will simply be a line in this case
        dragNode = SKShapeNode()
        dragNode.strokeColor = UIColor.white
        dragNode.lineWidth = 5
        dragNode.alpha = 0.5
        dragNode.zPosition = 50
        dragNode.path = dragPath
        
        addChild(dragNode)
    }
    
    func createBackground()
    {
        //Create the water texture for easy access
        let waterTexture = SKTexture(imageNamed: "WaterTexture")
        
        //Create a 6x6 grid of water tiles
        for row in -3...3
        {
            for col in -3...3
            {
                //Creat the node with the water texture
                let background = SKSpriteNode(texture: waterTexture)
                let size = waterTexture.size().width
                //Calculate the x/y coords of the tile to be added
                let x = CGFloat(row) * size
                let y = CGFloat(col) * size
                
                background.anchorPoint = CGPoint.zero
                background.position = CGPoint(x: x, y: y)
                
                addChild(background)
                
                //Create the parrallax animation effect that moves the water left and right
                let shiftLeft = SKAction.moveBy(x: -background.size.width / 10, y: -background.size.height / 2, duration: 3)
                let shiftRight = SKAction.moveBy(x: background.size.width / 10, y: -background.size.height / 2, duration: 3)
                let moveReset = SKAction.moveBy(x: 0, y: background.size.height, duration: 0)
                let sequence = SKAction.sequence([shiftLeft, shiftRight, moveReset])
                background.run(SKAction.repeatForever(sequence))
            }
        }
    }
    
    func createLabels()
    {
        //Create the score label that displays the score
        scoreLabel = SKLabelNode(fontNamed: "Optima-ExtraBlack")
        scoreLabel.fontSize = 24
        scoreLabel.position = CGPoint(x: frame.midX - frame.width / 10, y: frame.height / 2 - 20)
        scoreLabel.zPosition = 100
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.verticalAlignmentMode = .top
        scoreLabel.text = "Score: 0"
        scoreLabel.fontColor = UIColor.black
        
        addChild(scoreLabel)
        
        //Create the health label that displays the player's remaining life
        lifeLabel = SKLabelNode(fontNamed: "Optima-ExtraBlack")
        lifeLabel.fontSize = 24
        lifeLabel.position = CGPoint(x: frame.midX + frame.width / 12, y: frame.height / 2 - 20)
        lifeLabel.zPosition = 100
        lifeLabel.horizontalAlignmentMode = .left
        lifeLabel.verticalAlignmentMode = .top
        lifeLabel.text = "Life: 100%"
        lifeLabel.fontColor = UIColor.black
        
        addChild(lifeLabel)
    }
    
    func drawDragLine(point: CGPoint)
    {
        //Draws the line between the middle point and the inverted location of the player's tap
        dragNode.removeFromParent()
        dragPath = CGMutablePath()
        dragPath.move(to: CGPoint.zero)
        dragPath.addLine(to: point)
        
        dragNode = SKShapeNode()
        dragNode.strokeColor = UIColor.white
        dragNode.lineWidth = 10
        dragNode.alpha = 0.5
        dragNode.zPosition = 50
        dragNode.path = dragPath
        
        addChild(dragNode)
    }
    
    func spawnLilToots() //Fun method name: we nicknamed the tugboat image "Lil' Toot"
    {
        //Similar to createRocks from crashyPlane, this function spawns enemies on a loop.
        //This uses recursion to recalculate the delay between spawns
        let create = SKAction.run
        {
            self.createEnemy()
        }
        let wait = SKAction.wait(forDuration: spawnDelay)
        let recursion = SKAction.run
        {
            self.spawnLilToots()
        }
        let sequence = SKAction.sequence([create, wait, recursion])
        run(sequence)
    }
    
    func checkYoSelfBeforeYouRekYourself(bullet: SKShapeNode) //Just a fun method name, 
                                                              //this method handles the calculations of whether a bullet is in range to destory a boat
    {
        //Play an explosion effect at the bullet's location
        boomBoomBoomClap(at: bullet.position)
        
        //Go through all of the enemies and calculate the distance between them and the bullet
        for enemy in enemies
        {
            let xDist = bullet.position.x - enemy.position.x
            let yDist = bullet.position.y - enemy.position.y
            let distance = sqrt((xDist * xDist) + (yDist * yDist))
            
            //If the distance is small enough, then the ship gets destroyed.
            if distance < 60
            {
                //Play an explosion effect at the enemy's location too
                boomBoomBoomClap(at: enemy.position)
                //Remove the enemy from existence
                enemies.remove(at: enemies.index(of: enemy)!)
                enemy.removeFromParent()
                //Give the player a point
                score += 1
                //Change the delay period in between tugboat spawns
                spawnDelay *= 0.98
            }
        }
        
        //Calculate the distance between the bullet and the player
        let xDist = bullet.position.x - player.position.x
        let yDist = bullet.position.y - player.position.y
        let distance = sqrt((xDist * xDist) + (yDist * yDist))
        
        //If the player is in range of their own shot, then they get damaged too
        if distance < 70
        {
            life -= 5
        }
        
        //Once we finish handling this bullet, we can subtract it from the number of bullets
        numBullets -= 1
    }
    
    func lilTootTouchedTheButt() //Another fun method name
                                 //This function occurs when a tugboat reaches the center (the player)
    {
        //Subtract life from the player
        life -= 10
        //Play an explosion effect at the helicopter's location
        boomBoomBoomClap(at: CGPoint.zero)
        //If the player is out of life, then restart the game
        if life <= 0
        {
            let scene = GameScene(fileNamed: "GameScene")!
            scene.scaleMode = .resizeFill
            let transition = SKTransition.moveIn(with: .up, duration: 0)
            self.view?.presentScene(scene, transition: transition)
        }
    }
    
    func boomBoomBoomClap(at: CGPoint)
    {
        //Plays an explosion effect at the specified location
        if let explosion = SKEmitterNode(fileNamed: "PlayerExplosion")
        {
            explosion.position = at
            explosion.zPosition = 30
            //Specific case to play the effect on the helicopter if it is so specified.
            if at == CGPoint.zero
            {
                explosion.zPosition = 100
            }
            addChild(explosion)
        }
        
        //Also play the sound
        let sound = SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false)
        run(sound)
    }
}

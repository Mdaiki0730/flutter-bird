const fs = require('fs')
const traits = require("../input/traits.json");

function getRandomWeightedTrait(traitList, guaranteed = false) {

    // Calculate total weights
    let totalWeight = 0;
    traitList.forEach(function(trait) {
        if (!guaranteed || (trait.name !== "none" && trait.name !== "default")) {
            totalWeight += trait.weight
        }
    })

    // Get random number
    const randomNumber = Math.random() * totalWeight
    let weightCounter = 0;

    // Find trait for random number
    for (const trait of traitList) {
        if (guaranteed && (trait.name === "none" || trait.name === "default"))
            continue

        weightCounter += trait.weight
        if (weightCounter >= randomNumber) {
            if (trait.name === "none")
                return null;
            return trait.name
        }
    }
}


function generateMetadata(tokenId) {
    console.log('Creating metadata for skin ' + tokenId)

    const filename = '../output/metadata/#' + tokenId.toString() + '.json'

    // Check if metadata exists already
    if (fs.existsSync(filename)) {
        console.log('Metadata for skin with tokenId #' + tokenId + ' already exists')
        return
    }

    // Generate random metadata
    const skinTemplate = require('../input/metadata_template.json');
    const skinMetadata = Object.assign({}, JSON.parse(JSON.stringify(skinTemplate)));

    const guaranteedTrait = Math.floor(Math.random() * 4)

    const birdList = traits.bird;
    const headList = traits.head;
    const eyesList = traits.eyes;
    const mouthList = traits.mouth;
    const neckList = traits.neck;

    const randomBird = getRandomWeightedTrait(birdList)
    const randomHead = getRandomWeightedTrait(headList, guaranteedTrait === 0)
    const randomEyes = getRandomWeightedTrait(eyesList, guaranteedTrait === 1)
    const randomMouth = getRandomWeightedTrait(mouthList, guaranteedTrait === 2)
    const randomNeck = getRandomWeightedTrait(neckList, guaranteedTrait === 3)

    skinMetadata['name'] = 'Flutter Bird #' + tokenId.toString()
    skinMetadata['attributes'][0]['value'] = randomBird.toLowerCase()
    if (randomHead != null)
        skinMetadata['attributes'][1]['value'] = randomHead.toLowerCase()
    skinMetadata['attributes'][2]['value'] = randomEyes.toLowerCase()
    if (randomMouth != null)
        skinMetadata['attributes'][3]['value'] = randomMouth.toLowerCase()
    if (randomNeck != null)
        skinMetadata['attributes'][4]['value'] = randomNeck.toLowerCase()


    // Write metadata to json file

    const data = JSON.stringify(skinMetadata)
    fs.writeFileSync(filename, data)

    return skinMetadata;
}

module.exports = { generateMetadata }

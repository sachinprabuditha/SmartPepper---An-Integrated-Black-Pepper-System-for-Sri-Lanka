function getSeverityStage(severity) {
    if (severity <= 20) return 1;
    if (severity <= 40) return 2;
    if (severity <= 60) return 3;
    if (severity <= 80) return 4;
    return 5;
}

function getRemedies(disease, stage) {
    const diseaseLower = disease.toLowerCase().replace(/_/g, ' ');
    let chemical = [];
    let ecoFriendly = [];

    if (diseaseLower === 'footrot') {
        // --- FOOTROT (QUICK WILT) ---
        if (stage === 1) {
            chemical = [
                "The Leaf Shield: Mix 10g of Bordeaux powder in 1 liter of water. Spray this over the entire vine until leaves are dripping. This prevents the fungus from entering the plant."
            ];
            ecoFriendly = [
                "Lower Pruning: Cut all leaves and branches up to 1.5 feet from the ground. This stops fungus-filled mud from splashing onto the vine during heavy rain.",
                "Soil Fortification: Mix 1kg of Neem cake with 50g of Trichoderma. Spread this around the base and cover with a thin layer of soil. The 'good' fungus will eat the 'bad' fungus."
            ];
        } else if (stage === 2) {
            chemical = [
                "Base Drenching: Pour 3 liters of 1% Bordeaux mixture slowly at the base of the vine. It must soak deep into the soil to reach the main roots.",
                "Immunity Spray: Use Potassium Phosphonate (3ml per liter). This acts like a vaccine, making the plant's skin tougher against the fungus."
            ];
            ecoFriendly = [
                "Bio-Protection: Apply 10g of Pseudomonas powder mixed in 1 liter of water to the roots. These bacteria protect the roots like a bodyguard.",
                "Living Mulch: Spread 'Eupatorium' (wild sage) leaves around the base. As they rot, they naturally stop the fungus from moving."
            ];
        } else if (stage === 3) {
            chemical = [
                "Rescue Spray: If leaves are turning yellow, use Metalaxyl-Mancozeb (2g per liter). This is a strong medicine that travels inside the plant's veins to kill the disease."
            ];
            ecoFriendly = [
                "Sunlight Treatment: Trim the branches of the tall shade trees (like Silver Oak or Erythrina). If the sun hits the vine, the humidity drops and the fungus dies.",
                "Root Bath: Apply a Bacillus subtilis liquid mix to the root zone to help the plant grow new, healthy root hairs."
            ];
        } else if (stage === 4) {
            chemical = [
                "Stem Painting: Make a thick paste of Bordeaux mixture (like thick paint). Use a brush to paint the bottom 2 feet of the vine. This stops the 'collar rot' from killing the whole plant.",
                "Emergency Drench: Use a high-dose drench of systemic fungicides to stop the rot from reaching the heart of the vine."
            ];
            ecoFriendly = [
                "Plant Surgery: Carefully cut away the yellowing 'runner' shoots at the bottom. Take these pieces away from the farm and burn them immediately."
            ];
        } else if (stage === 5) {
            chemical = [
                "Site Sterilization: The soil is now infected. Mix Copper Oxychloride (2g/L) and soak the empty pit to prevent the disease from spreading to neighbors."
            ];
            ecoFriendly = [
                "The Sacrifice: Dig up the entire vine, including the root ball. Do not leave any pieces behind. Burn the vine. Do not plant pepper here for at least one year."
            ];
        }
    } else if (diseaseLower === 'pollu disease' || diseaseLower === 'pollu') {
        // --- POLLU DISEASE (BERRY DAMAGE) ---
        if (stage === 1) {
            chemical = ["Berry Protection: Spray 1% Bordeaux mixture specifically on the young berry strings (spikes) before the monsoon rains start."];
            ecoFriendly = [
                "Shade Regulation: Ensure the canopy only blocks 50% of the sun. More light means fewer beetles.",
                "Pupae Exposure: Lightly rake the soil around the vine base. This brings beetle 'babies' to the surface for birds to eat."
            ];
        } else if (stage === 2) {
            chemical = [
                "Beetle Attack: Spray Quinalphos (2ml per liter) in June and again in September. Target the clusters of pepper berries where the beetles hide."
            ];
            ecoFriendly = [
                "Neem-Garlic Wash: Mix 20ml Neem oil and 10g crushed garlic in water. Spray this every 15 days. The smell keeps the beetles from laying eggs on your pepper."
            ];
        } else if (stage === 5) {
            chemical = ["Soil Treatment: Apply Phorate granules into the top 2 inches of soil around the vine base to kill the beetles that sleep in the mud during winter."];
            ecoFriendly = [
                "Complete Harvest: Pick every single berry string, even the black ruined ones. If you leave them on the vine, the beetles will stay until next year."
            ];
        }
    } else if (diseaseLower === 'slow decline' || diseaseLower === 'slow-decline') {
        // --- SLOW DECLINE (ROOT NEMATODES) ---
        if (stage === 1) {
            chemical = ["Pre-Rain Guard: Sprinkle 30g of Carbofuran granules around the base just before the first monsoon rain hits."];
            ecoFriendly = [
                "Yearly Feeding: Every year, give each vine 12kg of well-rotted cow dung and 1kg of Neem cake. A well-fed vine can survive the root-worms."
            ];
        } else if (stage === 3) {
            chemical = ["Healing Drench: Use Metalaxyl-Mancozeb (2g/L). This stops the 'wound-rot' that happens after the root-worms bite the roots."];
            ecoFriendly = [
                "Root Aeration: Very gently loosen the soil around the vine with a small fork to let air reach the roots. Add fresh organic compost immediately after."
            ];
        } else if (stage === 5) {
            chemical = ["Soil Cleanse: Use a soil fumigant or heavy sterilization chemical before you ever think about planting a new vine in this spot."];
            ecoFriendly = [
                "Crop Rotation: Since the soil has root-worms, plant Ginger or Turmeric here for 1-2 years. These plants help clean the soil before you return to Pepper."
            ];
        }
    } else {
        chemical = ["Expert Advice: Take a fresh leaf and a handful of root-soil to the local agriculture office for a lab test."];
        ecoFriendly = ["General Hygiene: Keep the field free of weeds, as weeds often 'host' the bugs and fungus that attack pepper."];
    }

    return { chemical, ecoFriendly };
}

function calculateForecast(disease, severityVal) {
    const rates = {
        "Footrot": 6.0,
        "Pollu_Disease": 1.8,
        "Slow-Decline": 0.4
    };

    if (!(disease in rates) || severityVal <= 0) {
        return null;
    }

    const days = (100 - severityVal) / rates[disease];
    const stage = getSeverityStage(severityVal);
    const remedies = getRemedies(disease, stage);

    return {
        disease: disease.replace(/_/g, ' '),
        severity: severityVal,
        days_to_full_spread: parseFloat(days.toFixed(1)),
        stage: stage,
        remedies: remedies
    };
}

module.exports = {
    calculateForecast
};

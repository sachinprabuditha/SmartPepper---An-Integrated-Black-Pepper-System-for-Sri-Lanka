import admin from "firebase-admin";
import fs from "fs";

// load service account
const serviceAccount = JSON.parse(
    fs.readFileSync("./serviceAccountKey.json", "utf8")
);

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function importCollection(name, file) {
    console.log(`Importing ${name}...`);

    const data = JSON.parse(fs.readFileSync(file, "utf8"));

    for (const [id, doc] of Object.entries(data)) {
        await db.collection(name).doc(id).set(doc);
    }

    console.log(`✅ ${name} imported`);
}

async function run() {
    await importCollection("soilTypes", "./soilTypes.json");
    await importCollection("districts", "./districts.json");
    await importCollection("pepperVarieties", "./pepperVarieties.json");
    await importCollection("agronomyTemplates", "./agronomyTemplates.json");
    await importCollection("agronomyGuides", "./agronomyGuides.json");

    console.log("🎉 ALL DATA IMPORTED SUCCESSFULLY");
    process.exit(0);
}

run();

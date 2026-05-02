// test-google.cjs
const speech = require('@google-cloud/speech');
const { Translate } = require('@google-cloud/translate').v2;

async function test() {
  console.log('GOOGLE_APPLICATION_CREDENTIALS:', process.env.GOOGLE_APPLICATION_CREDENTIALS);

  // Test STT client initializes
  const speechClient = new speech.SpeechClient();
  console.log('✅ Speech client created');

  // Test Translate with a simple string
  const translate = new Translate();
  const [result] = await translate.translate('කළු මිරිස්', 'en');
  console.log('✅ Translation works:', result);
}

test().catch(err => {
  console.error('❌ Error:', err.message);
});
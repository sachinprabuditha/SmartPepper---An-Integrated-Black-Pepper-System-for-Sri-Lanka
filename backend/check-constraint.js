const db = require('./src/db/database');

async function checkConstraint() {
  try {
    const result = await db.query(`
      SELECT conname, pg_get_constraintdef(oid) as definition 
      FROM pg_constraint 
      WHERE conrelid = 'pepper_lots'::regclass AND contype = 'c';
    `);
    console.log(JSON.stringify(result.rows, null, 2));
    process.exit(0);
  } catch (error) {
    console.error(error.message);
    process.exit(1);
  }
}

checkConstraint();

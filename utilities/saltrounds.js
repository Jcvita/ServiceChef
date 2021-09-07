const bcrypt = require('bcrypt');

const TARGET_TIME = 250;

function salt(rounds) { 
    const password = "Abcdefghij1234!"
    var start = new Date();
    bcrypt.hashSync(password, rounds);
    var end = new Date();
    return end.getTime() - start.getTime();
}

count = 0;
while (salt(count) < TARGET_TIME) {
    count++;
}
console.log(`Rounds: ${count}\nTime (ms): ${salt(count)}`);
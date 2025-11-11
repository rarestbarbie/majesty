// combine.js
import fs from 'fs';
import path from 'path';
import { glob } from 'glob';
import JSON5 from 'json5';

// --- Get parameters from command line ---
const inputDir = process.argv[2];
const outputFile = process.argv[3];

if (!inputDir || !outputFile) {
    console.error('❗️ Usage: node combine.js <input_directory> <output_file>');
    process.exit(1);
}

const finalOutput = {};

try {
    // Find all files matching the pattern '_*.json' in the specified directory
    const files = glob.sync(path.join(inputDir, '*.jsonc'));

    if (files.length === 0) {
        console.warn(`⚠️ No files matching '*.jsonc' found in '${inputDir}'.`);
    }

    // --- Process each file ---
    files.forEach(filePath => {
        // 1. Derive the key from the filename: '_foo_bar.json' -> 'foo_bar'
        const baseName = path.basename(filePath, '.jsonc'); // Gets '_foo_bar'

        // 2. Read the JSON5 file content
        const fileContent = fs.readFileSync(filePath, 'utf8');
        const parsedContent = JSON5.parse(fileContent);

        // if first character is not an underscore, merge fields at top level
        if (baseName.charAt(0) !== '_') {
            Object.assign(finalOutput, parsedContent);
            console.log(`Processed: ${filePath} -> (toplevel)`);
        } else {
            const key = baseName.slice(1); // Removes the leading '_' to get 'foo_bar'
            finalOutput[key] = parsedContent;
            console.log(`Processed: ${filePath} -> key: '${key}'`);
        }
    });

    // --- Write the final combined object to the output file as standard JSON ---
    // JSON.stringify with null, 2 formats the output nicely.
    fs.writeFileSync(outputFile, JSON.stringify(finalOutput, null, 4));

    console.log(`\n✨ Success! Combined ${files.length} files into ${outputFile}`);

} catch (error) {
    console.error(`\n❌ An error occurred: ${error.message}`);
    process.exit(1);
}

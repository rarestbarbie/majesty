import fs from 'fs';
import { XMLParser } from 'fast-xml-parser';

// --- CONFIGURATION ---
const INPUT_FILE = 'Art/Icons/gender.svg'; // Adjusted path based on your previous logs
const OUTPUT_FILE = 'TypeScript/Stylesheets/generated/_gender.scss';
const VIEWBOX = '0 0 20 30';
const TARGET_LAYERS = ['XX', 'XF', 'XM', 'MM', 'MF', 'FF', 'FM'];

// --- HELPERS ---

function encodeSVG(pathData) {
    const svgBody = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${VIEWBOX}"><path d="${pathData}" fill="black"/></svg>`;
    const encoded = svgBody
        .replace(/"/g, "'")
        .replace(/>\s+</g, "><")
        .replace(/\s{2,}/g, " ")
        .replace(/[\r\n%#()<>?[\\\]^`{|}]/g, encodeURIComponent);
    return `url("data:image/svg+xml,${encoded}")`;
}

// --- MAIN EXECUTION ---

try {
    const xmlData = fs.readFileSync(INPUT_FILE, 'utf8');

    const parser = new XMLParser({
        ignoreAttributes: false,
        attributeNamePrefix: '@_',
        isArray: (name) => ['g', 'path'].indexOf(name) !== -1
    });

    const jsonObj = parser.parse(xmlData);
    let cssOutput = `:root {\n`;

    // Handle nested group structures often found in Inkscape
    const rootSvg = jsonObj.svg ? (Array.isArray(jsonObj.svg) ? jsonObj.svg[0] : jsonObj.svg) : {};
    const allGroups = rootSvg.g || [];

    TARGET_LAYERS.forEach(layerName => {
        const layerGroup = allGroups.find(g => g['@_inkscape:label'] === layerName);

        if (layerGroup) {
            const paths = layerGroup.path || [];

            // Find paths by label
            const leftPath = paths.find(p => p['@_inkscape:label'] === 'left');
            const rightPath = paths.find(p => p['@_inkscape:label'] === 'right');

            if (leftPath && leftPath['@_d']) {
                cssOutput += `  --icon-${layerName.toLowerCase()}-l: ${encodeSVG(leftPath['@_d'])};\n`;
            }
            if (rightPath && rightPath['@_d']) {
                cssOutput += `  --icon-${layerName.toLowerCase()}-r: ${encodeSVG(rightPath['@_d'])};\n`;
            }
        } else {
            console.warn(`Warning: Layer [${layerName}] not found in SVG.`);
        }
    });

    cssOutput += `}\n`;

    fs.writeFileSync(OUTPUT_FILE, cssOutput);
    console.log(`Success! CSS written to ${OUTPUT_FILE}`);

} catch (error) {
    console.error("Error processing SVG:", error.message);
}

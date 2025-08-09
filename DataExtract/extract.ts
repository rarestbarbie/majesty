import axios from 'axios';
import { CheerioAPI, load } from 'cheerio';
import { readFileSync, writeFileSync } from 'fs';

// Define the output data structure
interface SatelliteData {
    id: number; // This will be populated from the Code field
    name: string;
    orbit: {
        orbits: number;
        frame: string;
        a: number;
        e: number;
        i: number;
        ω: number;
        Ω: number;
    },
    tilt?: number;
}

async function scrape(): Promise<Record<string, SatelliteData>> {
    // Fetch the webpage content
    const response = await axios.get('https://ssd.jpl.nasa.gov/sats/elem/');
    const html = response.data;

    // Load the HTML into cheerio
    const page: CheerioAPI = load(html);

    // Find the data table
    const table = page('table');

    // Extract table headers
    const headers: string[] = [];
    table.find('thead tr th').each((_, element) => {
        headers.push(page(element).text().trim());
    });

    // Extract table rows
    const rows: Record<string, SatelliteData> = {};
    const planets: Record<string, number> = {
        'Earth': 399,
        'Mars': 499,
        'Jupiter': 599,
        'Saturn': 699,
        'Uranus': 799,
        'Neptune': 899,
        'Pluto': 999,
    };
    const columnsToKeep: string[] = [
        'Planet',
        'Satellite',
        'Code',
        'Frame',
        'a(km)',
        'e',
        'ω(deg)',
        'i(deg)',
        'node(deg)',
        'Tilt'
    ];


    table.find('tbody tr').each((_, row) => {
        const column: Record<string, string> = {};

        page(row).find('td').each((i, cell) => {
            const header = headers[i];
            if (columnsToKeep.includes(header)) {
                column[header] = page(cell).text().trim();
            }
        });

        if (Object.keys(column).length == 0) {
            return;
        }

        let frame: string;
        switch (column['Frame']) {
        case 'ecliptic':
            frame = 'C';
            break;
        case 'equatorial':
            frame = 'Q';
            break;
        case 'Laplace':
            frame = 'L';
            break;
        default:
            console.warn(`Unknown frame: ${column['Frame']}`);
            return;
        }

        const name: string = column['Satellite'];

        // Create a new object with 'id' as the Code
        const satellite: SatelliteData = {
            id: parseInt(column['Code'], 10),
            name: name == 'Moon' ? 'The Moon' : name,
            orbit: {
                orbits: planets[column['Planet']],
                frame: frame,
                a: parseFloat(column['a(km)']) / 149_597_870.700,
                e: parseFloat(column['e']),
                i: parseFloat(column['i(deg)']) * (Math.PI / 180),
                ω: parseFloat(column['ω(deg)']) * (Math.PI / 180),
                Ω: parseFloat(column['node(deg)']) * (Math.PI / 180)
            },
            tilt: parseFloat(column['Tilt']) || 0 // Default to 0 if Tilt is not available
        };

        if (satellite.name.startsWith('S20')) {
            return;
        }

        rows[satellite.name] = satellite;
    });

    return rows;
}

// Execute the scraping function
const satellites: Record<string, SatelliteData> = await scrape();

const json: {
    worlds: any[];
} = JSON.parse(readFileSync('../Client/start.json', 'utf8'));

for (const world of json['worlds']) {
    const satellite: SatelliteData | undefined = satellites[world['name']];
    if (!satellite) {
        continue;
    }
    world['orbit'] = satellite.orbit;
    world['id'] = satellite.id;
}

// Write the data to a JSON file
writeFileSync('output.json', JSON.stringify(json, null, 4));
console.log(`Successfully extracted ${Object.keys(satellites).length} satellites and saved to output.json`);

// Log the current date/time and user for reference
const currentDateTime = "2025-06-10 00:51:42"; // Using the provided timestamp
console.log(`Extraction completed at: ${currentDateTime} UTC`);
console.log(`Requested by: tayloraswift`);

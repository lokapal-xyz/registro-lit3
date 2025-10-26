const fs = require('fs');
const crypto = require('crypto');
const path = require('path');

/**
 * Strict normalization rules for chapter-style text:
 * 1. Read file as UTF-8
 * 2. Normalize Unicode to NFC form (composed form)
 * 3. Convert all line endings to LF (\n)
 * 4. Remove all trailing whitespace from each line
 * 5. Standardize blank lines (max 2 consecutive blank lines becomes 1)
 * 6. Remove leading whitespace from beginning of file
 * 7. Remove trailing whitespace from end of file
 * 8. Normalize all tabs to 4 spaces
 * 9. Strip BOM if present
 * 10. Ensure file ends with single newline
 */
function normalizeText(content) {
  // Step 1: Remove BOM if present
  if (content.charCodeAt(0) === 0xFEFF) {
    content = content.slice(1);
  }

  // Step 2: Normalize Unicode to NFC (composed form)
  content = content.normalize('NFC');

  // Step 3: Convert all line endings to LF (\n)
  content = content.replace(/\r\n/g, '\n').replace(/\r/g, '\n');

  // Step 4: Split into lines and process each
  let lines = content.split('\n');

  // Step 5: Remove trailing whitespace from each line
  lines = lines.map(line => line.replace(/\s+$/, ''));

  // Step 6: Normalize tabs to 4 spaces
  lines = lines.map(line => line.replace(/\t/g, '    '));

  // Step 7: Remove leading blank lines
  while (lines.length > 0 && lines[0].trim() === '') {
    lines.shift();
  }

  // Step 8: Remove trailing blank lines
  while (lines.length > 0 && lines[lines.length - 1].trim() === '') {
    lines.pop();
  }

  // Step 9: Collapse multiple consecutive blank lines (max 1 blank line between content)
  let normalizedLines = [];
  let lastWasBlank = false;

  for (let line of lines) {
    const isBlank = line.trim() === '';

    if (isBlank) {
      if (!lastWasBlank) {
        normalizedLines.push(line);
        lastWasBlank = true;
      }
      // Skip if previous line was also blank
    } else {
      normalizedLines.push(line);
      lastWasBlank = false;
    }
  }

  // Step 10: Join lines and ensure single trailing newline
  let normalized = normalizedLines.join('\n');

  // Ensure exactly one trailing newline
  normalized = normalized.replace(/\n*$/, '\n');

  return normalized;
}

/**
 * Compute SHA-256 hash of normalized content
 */
function computeHash(content) {
  return crypto.createHash('sha256').update(content, 'utf8').digest('hex');
}

/**
 * Main execution
 */
function main() {
  if (process.argv.length < 3) {
    console.error('Usage: node hnp1.js <input_file>');
    process.exit(1);
  }

  const filePath = process.argv[2];

  try {
    // Read file
    if (!fs.existsSync(filePath)) {
      console.error(`Error: File not found: ${filePath}`);
      process.exit(1);
    }

    const rawContent = fs.readFileSync(filePath, 'utf8');

    // Normalize
    const normalized = normalizeText(rawContent);

    // Hash
    const hash = computeHash(normalized);

    // Output as 0x-prefixed hex (solidity bytes32 format)
    const solidityHash = '0x' + hash;

    console.log(solidityHash);
  } catch (error) {
    console.error(`Error processing file: ${error.message}`);
    process.exit(1);
  }
}

main();
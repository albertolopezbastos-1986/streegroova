import { existsSync, writeFileSync } from 'node:fs';

// Godot must not scan npm dependencies when importing the project.
if (existsSync('node_modules')) writeFileSync('node_modules/.gdignore', '');

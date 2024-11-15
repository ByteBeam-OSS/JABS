const fs = require('fs');
const { google } = require('googleapis');

// Load environment variables
const ACCESS_TOKEN = process.env.ACCESS_TOKEN;
const BACKUP_FILE = process.argv[2]; // File path is passed as a command-line argument
const FOLDER_ID = process.env.DRIVE_FOLDER_ID || 'root'; // Default to root if not specified

if (!ACCESS_TOKEN || !BACKUP_FILE) {
  console.error('Error: Missing required environment variables or arguments.');
  process.exit(1);
}

// Authenticate with Google Drive
const auth = new google.auth.OAuth2();
auth.setCredentials({ access_token: ACCESS_TOKEN });
const drive = google.drive({ version: 'v3', auth });

// Upload the file
(async () => {
  try {
    const fileMetadata = {
      name: BACKUP_FILE.split('/').pop(), // Extract file name from path
      parents: [FOLDER_ID],
    };

    const media = {
      mimeType: 'application/gzip',
      body: fs.createReadStream(BACKUP_FILE),
    };

    const response = await drive.files.create({
      resource: fileMetadata,
      media: media,
      fields: 'id',
    });

    console.log(`File uploaded successfully: ${response.data.id}`);
  } catch (error) {
    console.error('Error uploading file:', error.message);
    process.exit(1);
  }
})();

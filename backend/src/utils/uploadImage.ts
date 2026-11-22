import cloudinary from '../config/cloudinary';

export const uploadToCloudinary = (fileBuffer: Buffer): Promise<string> => {
  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      { folder: 'nanaslush_products' },
      (error, result) => {
        if (error) return reject(error);
        if (result) return resolve(result.secure_url);
      }
    );
    uploadStream.end(fileBuffer);
  });
};
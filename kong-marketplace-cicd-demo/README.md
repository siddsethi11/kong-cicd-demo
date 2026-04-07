# Kong Marketplace CI/CD Demo

This project combines a frontend and backend application for a marketplace, utilizing Kong as an API Gateway. It includes a CI/CD pipeline set up with GitHub Actions to automate the deployment of the backend APIs to Kong Konnect and run Insomnia tests.

## Project Structure

- **applications/**: Contains the frontend and backend applications.
  - **marketplace-backend/**: The backend application built with Node.js and Express.
  - **marketplace-frontend/**: The frontend application built with React.

- **kong-config/**: Contains the configuration files for the Kong API Gateway.
  - **kong.yaml**: Main configuration file for Kong.
  - **consumers/**: Configuration files for consumers.
  - **global_plugins/**: Configuration files for global plugins.
  - **services/**: Configuration files for services and their routes.

- **testing/**: Contains the Insomnia collection for API testing.

- **scripts/**: Contains scripts for configuring and deploying the application.

- **.github/workflows/**: Contains the GitHub Actions workflow for CI/CD.

- **.env.template**: Template for environment variables.

- **.gitignore**: Specifies files to be ignored by Git.

## Setup Instructions

1. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd kong-marketplace-cicd-demo
   ```

2. **Install Dependencies**
   - For the backend:
     ```bash
     cd applications/marketplace-backend
     npm install
     ```
   - For the frontend:
     ```bash
     cd ../marketplace-frontend
     npm install
     ```

3. **Configure Environment Variables**
   - Copy the `.env.template` to `.env` and fill in the required values.

4. **Run the Applications Locally**
   - Start the backend:
     ```bash
     cd applications/marketplace-backend
     node server.js
     ```
   - Start the frontend:
     ```bash
     cd ../marketplace-frontend
     npm start
     ```

## CI/CD Workflow

The project includes a GitHub Actions workflow defined in `.github/workflows/kong-cicd.yml`. This workflow automates the following steps:

1. Deploy the backend APIs to the Kong API Gateway.
2. Run Insomnia tests using the Insomnia CLI.

## Testing

To run the Insomnia tests manually, you can use the Insomnia application to import the collection located in `testing/insomnia-collection.json`.

## Contributing

Feel free to submit issues or pull requests for any improvements or bug fixes.

## License

This project is licensed under the MIT License.
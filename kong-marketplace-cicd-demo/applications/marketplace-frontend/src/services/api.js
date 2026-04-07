import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_BASE_URL || 'http://localhost:3000';

const apiClient = axios.create({
    baseURL: API_BASE_URL,
    timeout: 10000,
});

// Example function to get products
export const getProducts = async () => {
    try {
        const response = await apiClient.get('/products');
        return response.data;
    } catch (error) {
        console.error('Error fetching products:', error);
        throw error;
    }
};

// Example function to get a single product
export const getProductById = async (id) => {
    try {
        const response = await apiClient.get(`/products/${id}`);
        return response.data;
    } catch (error) {
        console.error(`Error fetching product with id ${id}:`, error);
        throw error;
    }
};

// Example function to create a new product
export const createProduct = async (productData) => {
    try {
        const response = await apiClient.post('/products', productData);
        return response.data;
    } catch (error) {
        console.error('Error creating product:', error);
        throw error;
    }
};

// Example function to update a product
export const updateProduct = async (id, productData) => {
    try {
        const response = await apiClient.put(`/products/${id}`, productData);
        return response.data;
    } catch (error) {
        console.error(`Error updating product with id ${id}:`, error);
        throw error;
    }
};

// Example function to delete a product
export const deleteProduct = async (id) => {
    try {
        await apiClient.delete(`/products/${id}`);
    } catch (error) {
        console.error(`Error deleting product with id ${id}:`, error);
        throw error;
    }
};
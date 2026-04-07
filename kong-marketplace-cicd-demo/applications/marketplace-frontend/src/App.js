import React from 'react';
import { BrowserRouter as Router, Route, Switch } from 'react-router-dom';
import Header from './components/Header';
import ProtectedRoute from './components/ProtectedRoute';
import HomePage from './pages/index';
import CartPage from './pages/CartPage';
import ProductsPage from './pages/ProductsPage';
import OrdersPage from './pages/OrdersPage';
import PaymentsPage from './pages/PaymentsPage';
import ReviewsPage from './pages/ReviewsPage';
import UsersPage from './pages/UsersPage';
import CategoriesPage from './pages/CategoriesPage';

const App = () => {
    return (
        <Router>
            <Header />
            <Switch>
                <Route path="/" exact component={HomePage} />
                <ProtectedRoute path="/cart" component={CartPage} />
                <ProtectedRoute path="/products" component={ProductsPage} />
                <ProtectedRoute path="/orders" component={OrdersPage} />
                <ProtectedRoute path="/payments" component={PaymentsPage} />
                <ProtectedRoute path="/reviews" component={ReviewsPage} />
                <ProtectedRoute path="/users" component={UsersPage} />
                <ProtectedRoute path="/categories" component={CategoriesPage} />
            </Switch>
        </Router>
    );
};

export default App;
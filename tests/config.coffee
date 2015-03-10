module.exports = {
    rootUrl: "http://localhost:8888/acenda/bones/",
    store: "store",
    rand: Math.floor(Math.random()*1000000000),
    token_reset: null,
    user: {
        first_name: "Test",
        last_name: "Test",
        phone_number: "7600000000",
        email: "",
        confirm_email: "",
        password: "",
        confirm_password: "",
        company: "TorreyCommerce-Acenda"
    },
    collections: [
        '/product/dena-happi-tree-bedding',
        '/product/performance-sport',
        '/product/cortina-keyfit-travel-system'
    ],
    address: {
        street_line1: "8400 Miramar Rd",
        street_line2: "Ste 290",
        city: "San Diego",
        state: 5,
        zip: "92126",
        country: 0
    },
    wishlist: {
        private: {
            name: "Test Wishlist Private",
            privacy: "private",
            address: 0
        },
        public: {
            name: "Test Wishlist Public",
            privacy: "public",
            address: 0
        },
        unlisted: {
            name: "Test Wishlist Unlisted",
            privacy: "unlisted",
            address: 0
        }
    },
    registry: {
        private: {
            name: "Test Registries Private",
            privacy: "private",
            date: "2015-06-18",
            address: 0
        },
        public: {
            name: "Test Registries Public",
            privacy: "private",
            date: "2015-05-19",
            address: 0
        },
        unlisted: {
            name: "Test Registries Unlisted",
            privacy: "private",
            date: "2015-04-20",
            address: 0
        }
    },
    products: [
        "turtle-reef-crib-bedding",
        "cortina-keyfit-travel-system",
        "swim-nappy-large",
        "drink-thingy",
        "gnaw"
    ]
}

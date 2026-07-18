import { useEffect, useMemo, useState, useSyncExternalStore } from "react";
import { createClient } from "@supabase/supabase-js";
import { SUPABASE_URL, SUPABASE_ANON_KEY } from "./supabaseConfig.js";

/* ================================================================
   LE KREAMERY — QR TABLE ORDERING
   Architecture: the UI never talks to a POS directly. It talks to a
   POSAdapter interface. MockPOSAdapter (below) is the demo/pilot
   implementation (in-memory). To go live against GAAP / Lightspeed,
   write a new class with the same methods and swap it in one line.
   Payments: payWithProvider() is a stub where the Yoco SDK
   (Apple Pay + card) drops in. See README.
   ================================================================ */

/* ----------------------------- THEME --------------------------- */
const T = {
  ink: "#2b2b2b",
  sub: "#8a8f98",
  paper: "#f3f4f6",
  card: "#ffffff",
  gold1: "#c99f5f",
  gold2: "#9a763a",
  amber: "#dd9a3c",
  dark: "#17181b",
  line: "#e5e7eb",
  ok: "#3f9d63",
  warn: "#d97706",
};
const goldText = {
  backgroundImage: `linear-gradient(100deg, ${T.gold1}, ${T.gold2})`,
  WebkitBackgroundClip: "text",
  backgroundClip: "text",
  color: "transparent",
};

/* ------------------------ OPTION GROUPS -------------------------
   type: "single" (required choice) | "multi" (optional extras)     */
const G = {
  pastaType: { name: "Choose your pasta", type: "single", options: [["Penne", 0], ["Spaghetti", 0], ["Linguini", 0]] },
  grillSide: { name: "Choose your side", type: "single", options: [["Chips", 0], ["Mashed Potatoes", 0], ["Spicy Rice", 0], ["Salad", 0]] },
  sauce4: { name: "Choose your sauce", type: "single", options: [["Lemon Butter", 0], ["Peri Peri", 0], ["French Butter", 0], ["Madeira", 0]] },
  sauce3: { name: "Choose your sauce", type: "single", options: [["Lemon Butter", 0], ["Peri Peri", 0], ["French Butter", 0]] },
  bread4: { name: "Choose your bread", type: "single", options: [["White", 0], ["Brown", 0], ["Low GI", 0], ["Rye", 0]] },
  creamIce: { name: "Served with", type: "single", options: [["Ice Cream", 0], ["Whipped Cream", 0]] },
  gelato: { name: "Upgrade", type: "multi", options: [["Gelato scoop (enquire on flavours)", 40]] },
  chickFlav: { name: "Choose your flavour", type: "single", options: [["Lemon and Herb", 0], ["Peri Peri", 0], ["Bazaruto", 0]] },
  periFlav: { name: "Choose your flavour", type: "single", options: [["Peri Peri", 0], ["Mild Peri Peri", 0], ["Lemon and Herb", 0]] },
  eggChoice: { name: "Choose your eggs", type: "single", options: [["Fried Eggs", 0], ["Masala Scrambled Eggs", 0]] },
  breadRC: { name: "Choose your bread", type: "single", options: [["Ciabatta", 0], ["Rye", 0]] },
  wrapSide: { name: "Choose your side", type: "single", options: [["Chips", 0], ["Salad", 0], ["Spicy Rice", 0]] },
  brekAdd: {
    name: "Add to your breakfast", type: "multi",
    options: [["Cheese Griller / Sausage", 30], ["Hash Browns", 20], ["Paratha", 35], ["Slice Toast", 15], ["Macon / Polony", 25], ["Chips", 35], ["Tomato", 20], ["Slice Cheese", 20], ["Aloo Fry", 25]],
  },
  pzCheese: { name: "Extra cheeses", type: "multi", options: [["Cream Cheese & Chives", 40], ["Feta", 35], ["Mozzarella", 40], ["Haloumi", 50]] },
  pzHerb: { name: "Herbs", type: "multi", options: [["Basil", 20], ["Rocket", 20], ["Crushed Garlic", 20], ["Chillies", 20]] },
  pzVeg: { name: "Veggies", type: "multi", options: [["Avocado", 60], ["Bananas", 15], ["Tomatoes", 40], ["Green Peppers", 35], ["Jalapeño", 40], ["Mushrooms", 40], ["Olives", 40], ["Onions", 35], ["Peppadews", 40], ["Pineapple", 35]] },
  pzMeat: { name: "Meat & seafood", type: "multi", options: [["Spicy Beef Strips", 65], ["Chicken", 60], ["Chicken Peri Peri", 60], ["Chicken Sweet Chilli", 60], ["Pepperoni", 35], ["Shrimp", 85]] },
  shakeFlav: { name: "Choose your flavour", type: "single", options: [["Strawberry Supreme", 0], ["Banana Cream Pie", 0], ["Lime & Love", 0], ["Chocolate Kreamer", 0], ["Vanilla", 0], ["Bubblegum Bliss", 0]] },
  gShakeFlav: { name: "Choose your flavour", type: "single", options: [["Candy Floss", 0], ["Nutella", 0], ["Oreo", 0], ["Crème Brûlée", 0], ["Tiramisu", 0], ["Ferrero", 0], ["Turkish Delight", 0], ["Caramel Popcorn", 0], ["Coffee", 0], ["Saffron", 0], ["Pistachio", 0], ["Lotus", 0]] },
  shakeX: { name: "Make it yours", type: "multi", options: [["Double thick", 15], ["Shot glasses for sharing (single flavour)", 15]] },
  milkX: { name: "Add", type: "multi", options: [["Cream", 15], ["Almond Milk", 15]] },
  loaded: { name: "Style", type: "multi", options: [["Fully loaded (fried)", 15]] },
};

/* --------------------------- MENU DATA --------------------------
   i = item: n name, p price (or v variants [[label, price]]), d desc,
   g option-group keys, x item-specific multi extras [[name, price]],
   sq = price on request (not orderable online)                      */
const MENU = [
  {
    cat: "Breakfast", note: "Served all day",
    items: [
      { n: "South African Breakfast", p: 105, d: "2 fried eggs, 2 sausages, 2 slices toast, baked beans", g: ["brekAdd"] },
      { n: "Bombay Breakfast", p: 115, d: "2 eggs, aloo fry, polony or macon, cheese grillers, paratha", g: ["eggChoice", "brekAdd"] },
      { n: "Swiss Steak Breakfast", p: 200, d: "2 eggs, cheddar, 100g BBQ steak strips, caramelised onion, chilli, Kremo sauce on an English muffin", g: ["brekAdd"] },
      { n: "Flavours of Spain Omelette", p: 105, d: "Cheddar, onion, mushroom, tomato, hash brown pieces, fresh chilli", g: ["brekAdd"] },
      { n: "Turkish Eggs", p: 125, d: "2 poached eggs, spiced yoghurt, chilli oil, olives, crumbled feta on clay-oven naan", g: ["brekAdd"] },
      { n: "Arabian Breakfast", p: 115, d: "Hummus, rocket, avo, signature feta, fried egg on ciabatta or rye", g: ["breadRC", "brekAdd"] },
      { n: "Princess", p: 130, d: "Hazelnut crumble granola, Krema yoghurt, papaya, strawberry, banana" },
      { n: "Sultan Breakfast Platter", p: 175, d: "2 eggs, 4 kebabs, 2 sausages, naan, red chutney, tikka hollandaise, hummus, feta, peppadew, halloumi, green chilli", g: ["brekAdd"] },
      { n: "Tikka Eggs Benedict", p: 140, d: "2 poached eggs, curried spinach, halloumi, aloo fry on naan with tikka hollandaise", x: [["Chicken Fillet", 55], ["Hummus", 30], ["Mushrooms", 20], ["Polony", 25]] },
      { n: "Eggs Benedict", p: 95, d: "2 poached eggs on an English muffin with hollandaise", x: [["Salmon", 65], ["Avocado", 40]] },
      { n: "Smash Avo Toast", p: 105, d: "Smashed avo, feta, pomegranate or strawberry (seasonal), rubies, sweet balsamic reduction", x: [["Poached Egg", 12]] },
      { n: "French Toast", p: 125, d: "Berry & mascarpone" },
      { n: "Paw Paw Face", p: 105, d: "Papaya, low-fat Greek yoghurt, honey, pomegranate or strawberry (seasonal)" },
    ],
  },
  {
    cat: "Healthy Eating",
    items: [
      { n: "The Ritz Salad", p: 85, d: "Feta, lettuce, Kalamata olives, purple onion, cucumber, house dressing", x: [["Butternut", 25], ["Peri Chicken Fillet", 55], ["Halloumi", 50], ["Avocados", 35]] },
      { n: "Abu Dhabi Garden Salad", p: 185, d: "Lettuce, feta, olives, chicken, hummus, Kremo dressing, ciabatta dipping bread" },
      { n: "Méditerranée Salad", p: 185, d: "Grilled Portuguese chicken, lettuce, pineapple, avo, sweet sriracha mayo, creamy house dressing" },
      { n: "Luxury Haloumi, Hummus & Avo Wrap", p: 135, d: "Grilled haloumi, avo, hummus in a whole-wheat wrap with a side", g: ["wrapSide"] },
      { n: "Creamy Chicken Mozzarella Wrap", p: 165, d: "Grilled chicken, mozzarella, pepper dews, sour cream, cucumber, tomato, with a side", g: ["wrapSide"] },
      { n: "Creamy Grape Salad", p: 155, d: "Red & white grapes, cream cheese, carb-free granola, honey, pomegranate (traces of nuts)" },
      { n: "Spring Onion Cheeza", p: 135, d: "Flat rye bread, creamy mozzarella & gouda mix, spring onion", x: [["Mushrooms", 20], ["Polony / Macon Bits", 25], ["Chicken", 55], ["Haloumi", 50]] },
    ],
  },
  {
    cat: "Smoothies", note: "Fresh fruit blends · subject to availability",
    items: [
      { n: "Refresh-mint", p: 75, d: "Avocado, mango, mint" },
      { n: "Tropical Split", p: 75, d: "Coconut, banana, pineapple, mango" },
      { n: "Açai Kick", p: 75, d: "Blueberry, mango, banana" },
      { n: "Caribbean Kiss", p: 75, d: "Melon, strawberry" },
      { n: "Cherry Split", p: 75, d: "Cherry, papaya" },
      { n: "Paradise Bliss", p: 75, d: "Pineapple, passionfruit" },
      { n: "Blueberry Split", p: 75, d: "Blueberry, banana" },
    ],
  },
  {
    cat: "Starters",
    items: [
      { n: "Jalapeño Cheese Fries", p: 75, d: "Fries with classic cheesy sauce and jalapeños" },
      { n: "Cajun Cream Calamari", p: 125, d: "Calamari tubes in Cajun cream sauce, shoestring fries", x: [["Stuffed with Peppadew", 20], ["Stuffed with Jalapeño", 20], ["Stuffed with Feta", 25], ["Stuffed with Shrimp", 85]] },
      { n: "Prawn Gratin", p: 135, d: "6 de-shelled prince prawns in creamy peri cheddar & feta sauce, ciabatta" },
      { n: "Haloumi Starter", p: 95 },
      { n: "World Famous Kebabs", p: 135, d: "6 lemon-infused kebabs with a paratha" },
      { n: "Philly Cheese Steak Folds", p: 105, d: "3 folds with signature Kremo sauce" },
      { n: "Fried Macaroni & Cheese Balls", p: 95, d: "With signature Kremo sauce" },
      { n: "Nachos", p: 90, d: "Tortilla chips, jalapeños, salsa, guacamole, sour cream", x: [["Spicy Chicken", 35], ["Beef", 40]] },
      { n: "Cheesy Garlic Bread", p: 85, x: [["Olives", 20], ["Jalapeño", 15], ["Pepperoni", 30], ["Peri Chicken", 60]] },
      { n: "New Orleans Cheesy Garlic Bread", p: 110, d: "Steak strips, caramelised onions, Kremo sauce" },
      { n: "Saucy Tandoori Prawns", p: 165, d: "6 de-shelled prince prawns in tandoori sauce, ciabatta" },
      { n: "LK Bang Bang Popcorn Chicken", p: 155, d: "Crispy chicken bites in spicy dynamite sauce, served in a vintage popcorn machine" },
      { n: "LK Bang Bang Popcorn Shrimp", p: 165, d: "6 crispy shrimp in spicy dynamite sauce, popcorn-machine style" },
      { n: "Grilled Edamame Beans", p: 110, d: "Asian teriyaki, steaming in the shell" },
      { n: "Creamy Hummus", p: 85, d: "With grilled ciabatta" },
      { n: "Butternut Soup", p: 85, d: "Cinnamon, fresh cream, hint of chilli, ciabatta" },
    ],
  },
  {
    cat: "Pizza", note: "Hand-tossed · fresh dough daily",
    items: [
      { n: "Create Your Own — Margarita", p: 95, d: "Base, pizza sauce, mozzarella", g: ["pzCheese", "pzHerb", "pzVeg", "pzMeat"] },
      { n: "Create Your Own — Rosso", p: 85, d: "Base & signature pizza sauce", g: ["pzCheese", "pzHerb", "pzVeg", "pzMeat"] },
      { n: "Create Your Own — Hummus", p: 95, d: "Base, hummus spread, mozzarella", g: ["pzCheese", "pzHerb", "pzVeg", "pzMeat"] },
      { n: "Mumbai", p: 200, d: "Spicy potato and chutneys between two pizza bases", g: ["pzCheese", "pzHerb", "pzVeg", "pzMeat"] },
      { n: "The LK Pizza", p: 175, d: "Feta, peri chicken, green chilli", g: ["pzCheese", "pzHerb", "pzVeg", "pzMeat"] },
      { n: "Kebab Pizza", p: 185, d: "Margarita base, world-famous kebabs, special Kremo sauce", g: ["pzCheese", "pzHerb", "pzVeg", "pzMeat"] },
      { n: "Boston", p: 195, d: "Steak strips, caramelised onions, green peppers, Kremo sauce", g: ["pzCheese", "pzHerb", "pzVeg", "pzMeat"] },
      { n: "Butter Chicken Pizza", p: 185, d: "Butter chicken, peppadews, creamy mayo", g: ["pzCheese", "pzHerb", "pzVeg", "pzMeat"] },
      { n: "Tandoori Prawn Pizza", p: 220, d: "Vibrant peppers, spicy feta, chilli, rich tandoori sauce", g: ["pzCheese", "pzHerb", "pzVeg", "pzMeat"] },
    ],
  },
  {
    cat: "Bruschetta", note: "Open bread sandwich on bruschetta bread",
    items: [
      { n: "The Rosa", p: 90, d: "Rosa tomatoes, Kalamata olives, cubed feta" },
      { n: "The Halloumi Fromage", p: 105, d: "Grilled halloumi, fancy lettuce, parsley, sweet chilli sauce" },
      { n: "Marco Polo", p: 120, d: "Sliced chicken breast in Kremo sauce, fancy lettuce, chives" },
    ],
  },
  {
    cat: "Pasta", note: "Choice of penne, spaghetti or linguini",
    items: [
      { n: "Napolitana", p: 90, d: "Tomato & herbs", g: ["pastaType", "pzHerb", "pzVeg"] },
      { n: "Arrabiata", p: 95, d: "Tomato, garlic, chilli & herbs", g: ["pastaType", "pzHerb", "pzVeg"] },
      { n: "Alfredo", p: 110, d: "Creamy white sauce with mushrooms", g: ["pastaType", "pzHerb", "pzVeg"], x: [["Chicken Strips", 60], ["Macon Bits", 25]] },
      { n: "LK Peri Pasta", p: 165, d: "Creamy white sauce, peri chicken strips, mushrooms", g: ["pastaType", "pzHerb", "pzVeg"] },
      { n: "New York Mac & Cheese", p: 105, d: "Clay-oven cheesy baked macaroni", g: ["pzHerb", "pzVeg"] },
      { n: "The Rockefella", p: 175, d: "6 de-shelled medium prawns in Cajun cream sauce", g: ["pastaType", "pzHerb", "pzVeg"] },
      { n: "Creamy Truffel & Steak", p: 200, d: "Creamy peppercorn mushroom sauce, steak strips", g: ["pastaType", "pzHerb", "pzVeg"] },
    ],
  },
  {
    cat: "Grills", note: "Served with your choice of chips, mash, spicy rice or salad · Angus & Wagyu cuts SQ — ask your waitron",
    items: [
      { n: "Clay Oven French Butter Steak", d: "200g speciality cut, slow cooked in LK steak butter, rosemary, garlic & thyme — Our Signature", v: [["Grass Fed Fillet 200g", 350]], g: ["grillSide"] },
      { n: "Creamy Peri Peri Gourmet Steak", d: "200g steak topped with creamy peri peri sauce — Our Signature", v: [["Grass Fed Fillet 200g", 350], ["Rump", 235]], g: ["grillSide"], x: [["Jalapeño", 20], ["Feta", 35]] },
      { n: "Classic Beef Fillet", d: "200g fillet, house spices or smoky BBQ basting", v: [["Grass Fed Fillet 200g", 285], ["Rump", 220]], g: ["grillSide"] },
      { n: "Genova Butter Steak", d: "Fillet in creamy garlic & herb butter, chips and garlic bread", v: [["Grass Fed Fillet 200g", 350]] },
      { n: "Algarve Clay Oven Steak", d: "Portuguese spiced fillet, slow cooked, creamy lemon herb butter sauce", v: [["Grass Fed Fillet 200g", 350]], g: ["grillSide"] },
      { n: "Cheesy Melt Steak", d: "200g steak topped with cheese sauce", v: [["Grass Fed Fillet 200g", 350], ["Rump", 235]], g: ["grillSide"], x: [["Jalapeño", 20], ["Mushroom", 20]] },
      { n: "Le Kreamery Lamb Chops", p: 275, d: "3 lamb chops basted & grilled in special basting sauce", g: ["grillSide"], x: [["Creamy Peri Peri Sauce", 50]] },
      { n: "French Butter Lamb Chops", p: 295, d: "3 lamb chops basted & grilled in French butter", g: ["grillSide"] },
      { n: "Clay Oven Chicken", d: "Grilled basted organic chicken, slow cooked in the clay oven", v: [["Half", 155], ["Full Chicken", 260]], g: ["chickFlav", "grillSide"] },
      { n: "Grilled Peri Chicken Fillet", p: 135, d: "2 grilled chicken fillets", g: ["periFlav", "grillSide"] },
    ],
  },
  {
    cat: "Seafood", note: "Served with Spanish rice and chips · LM Prawns, Tiger Giants & Langoustines SQ — ask your waitron",
    items: [
      { n: "Prince Prawns", p: 280, d: "10 prince prawns", g: ["sauce4"] },
      { n: "Queen Prawns", p: 350, d: "8 queen prawns", g: ["sauce4"] },
      { n: "King Prawns", p: 450, d: "6 king prawns", g: ["sauce4"] },
      { n: "Hake", p: 230, d: "Grilled hake", g: ["sauce3"] },
      { n: "Grilled Pangasius", p: 260, d: "Soft, scaleless fish, grilled", g: ["sauce3"] },
      { n: "Prince Prawn Platter (1kg)", p: 580, g: ["sauce4"] },
      { n: "Queen Prawn Platter (1kg)", p: 650, g: ["sauce4"] },
      { n: "King Prawn Platter (1kg)", p: 850, g: ["sauce4"] },
    ],
  },
  {
    cat: "Between Breads", note: "Triple-sliced sandwich, bread of your choice, double-coated fries",
    items: [
      { n: "Toasted Cheese & Tomato", p: 80, g: ["bread4"] },
      { n: "Toasted Tuna & Mayo", p: 95, g: ["bread4"] },
      { n: "Toasted Chicken & Mayo", p: 95, g: ["bread4"] },
      { n: "Le Kreamery Toasted Steak", p: 115, g: ["bread4"] },
      { n: "Mumbai Sandwich", p: 105, d: "Aloo fry & gouda blended in homemade chutneys", g: ["bread4"] },
      { n: "New Orleans Cheesy Steak", p: 135, d: "Steak, peppers, mozzarella, gouda, caramelised onions, Kremo sauce", g: ["bread4"] },
      { n: "Jalapeño Cheese Popper Sandwich", p: 105, d: "Gouda, jalapeños, cream cheese", g: ["bread4"] },
      { n: "Kremo Peri Chicken", p: 130, d: "Peri chicken, Kremo sauce, jalapeños", g: ["bread4"] },
    ],
  },
  {
    cat: "Burgers", note: "Served with double-coated fries",
    items: [
      { n: "Jalapeño Kremo Steak Burger", d: "100g steak stuffed with jalapeño, cheese, onion rings, Kremo sauce, glazed bun", v: [["Rump", 125], ["Grass Fed Fillet", 175]] },
      { n: "Butter Chicken Burger", p: 120, d: "Creamy butter-chicken-style fillet in a bun" },
      { n: "Ms LK Burger", p: 125, d: "Beef patty, lettuce, tomato, cheese, caramelised onions, jalapeño, Kremo sauce" },
      { n: "Mr LK Burger", p: 155, d: "2 beef patties, lettuce, tomato, double cheese, chilli, jalapeño, caramelised onions, Kremo sauce" },
      { n: "Chick Kream Burger", p: 120, d: "Chicken fillet, lettuce, tomato, secret sauce" },
      { n: "Bistro Melt Burgers", p: 185, d: "Two grass-fed burgers, melted cheese, jalapeños, onion rings, Kremo sauce, cream buns, creamy peppercorn mushroom sauce, golden fries" },
    ],
  },
  {
    cat: "Gourmet Sushi", note: "All can be made fully loaded (fried) at R15 extra",
    items: [
      { n: "California Rolls ReKreamed (4pc)", d: "Avo, caviar, creamy mayo, Kremo sauce, crispy onion rings", v: [["Prawn", 120], ["Salmon", 120]], g: ["loaded"] },
      { n: "Butter Chicken Rolls (4pc)", p: 120, d: "Chicken fillet topping, avo & peppadew, creamy mayo, crispy potato strings, butter chicken sauce, deep fried" },
      { n: "Thai Steak Rolls (4pc)", p: 120, d: "Steak strips, Thai BBQ sauce, avo, Kremo sauce, onion rings, jalapeños, cheese sauce, deep fried" },
    ],
  },
  {
    cat: "Classic Sushi",
    items: [
      { n: "California Rolls — Norwegian Salmon", v: [["4 Piece", 85], ["8 Piece", 135]], g: ["loaded"] },
      { n: "California Rolls — Prawn", v: [["4 Piece", 85], ["8 Piece", 135]], g: ["loaded"] },
      { n: "California Rolls — Veg", v: [["4 Piece", 75], ["8 Piece", 110]], g: ["loaded"] },
      { n: "Sashimi (4pc) — Norwegian Salmon", p: 135, d: "Raw or seared, no rice" },
      { n: "Nigiri (2pc)", v: [["Salmon", 90], ["Prawn", 90], ["Veg (Avo)", 75]] },
      { n: "Fusion Sandwiches (8pc)", v: [["Salmon", 150], ["Prawn", 150], ["Veg (Avo)", 125]] },
      { n: "Roses (2pc) — Salmon", p: 90 },
    ],
  },
  {
    cat: "World Famous Desserts",
    items: [
      { n: "Saffron Milk Cake", p: 105, d: "Saffron sponge, saffron milk sauce, light cream (contains nuts)" },
      { n: "Pistachio Milk Cake", p: 105, d: "Pistachio sponge, pistachio milk sauce, light cream (contains nuts)" },
      { n: "Kremlitz", p: 85, d: "4 crispy pastries, cream cheese & cinnamon, creamy caramel sauce" },
      { n: "Lindt Crepe", p: 160, d: "Serves 2 · extra-long crepe, strawberries & banana, Lindt chocolate (contains nuts)" },
      { n: "Sizzling Brownie", p: 95, d: "Swiss chocolate brownie on a sizzling pan, vanilla ice cream (contains nuts)" },
      { n: "Sizzling Malva Pudding", p: 95, d: "Malva pudding with sizzling custard (subject to availability)" },
      { n: "Fried Oreo & Churro Platter", d: "Deep-fried Oreos and churros with your choice of sauce", v: [["Nutella (contains nuts)", 110], ["White Chocolate", 110], ["Kinder", 120], ["Lotus", 120]] },
      { n: "Lotus Volcano Cake", p: 125, d: "Serving for two" },
      { n: "LK Dynamite Mousse", p: 125, d: "Edible dynamite in a signature chocolate shell, silky chocolate mousse, sparkling pre-explosion at your table" },
    ],
  },
  {
    cat: "Waffles",
    items: [
      { n: "Honey / Golden Syrup Waffle", p: 75, g: ["creamIce", "gelato"] },
      { n: "White Chocolate Overload Waffle", p: 95, d: "Milk or white chocolate overload", g: ["creamIce", "gelato"] },
      { n: "Caramel Crunch Waffle", p: 95, d: "Signature caramel sauce & nuts (contains nuts)", g: ["creamIce", "gelato"] },
      { n: "Nutella Waffle", p: 95, d: "(Contains nuts)", g: ["creamIce", "gelato"] },
      { n: "Lindor Waffle", p: 120, d: "Lindor milk chocolate sauce", g: ["creamIce", "gelato"] },
      { n: "Lotus Waffle", p: 115, d: "Subject to availability", g: ["creamIce", "gelato"] },
    ],
  },
  {
    cat: "Grande Waffles",
    items: [
      { n: "S'more", p: 135, d: "Nutella, roasted marshmallows, Oreos", g: ["creamIce", "gelato"] },
      { n: "Raffaello", p: 120, d: "Raffaello sauce & chocolate", g: ["creamIce", "gelato"] },
      { n: "Kinder Bueno", p: 155, d: "Kinder chocolate sauce & Kinder Bueno", g: ["creamIce", "gelato"] },
      { n: "Crème Brûlée Waffle", p: 125, d: "Crème brûlée sauce, cinnamon fried banana", g: ["creamIce", "gelato"] },
      { n: "Ferrero Waffle", p: 155, d: "Ferrero cream (contains nuts)", g: ["creamIce", "gelato"] },
    ],
  },
  {
    cat: "Pancakes", note: "Served with your choice of cream or ice cream",
    items: [
      { n: "Cinnamon & Sugar", p: 55, g: ["creamIce", "gelato"] },
      { n: "Caramel & Nut Crunch", p: 85, g: ["creamIce", "gelato"] },
      { n: "White Chocolate & Oreo", p: 85, g: ["creamIce", "gelato"] },
      { n: "Nutella Pancakes", p: 90, g: ["creamIce", "gelato"] },
      { n: "Kinder Pancakes", p: 115, g: ["creamIce", "gelato"] },
      { n: "Lotus & Banana", p: 110, g: ["creamIce", "gelato"] },
      { n: "Lindor & Oreo", p: 115, g: ["creamIce", "gelato"] },
      { n: "French Pancakes", p: 115, d: "Berries, mascarpone & syrup", g: ["creamIce", "gelato"] },
      { n: "Pistachio & Strawberry", p: 115, g: ["creamIce", "gelato"] },
      { n: "Lemon Meringue", p: 115, g: ["creamIce", "gelato"] },
      { n: "Ferrero Pancakes", p: 115, g: ["creamIce", "gelato"] },
      { n: "Butterscotch & Banana", p: 115, g: ["creamIce", "gelato"] },
      { n: "Crème Brûlée Pancakes", p: 115, g: ["creamIce", "gelato"] },
    ],
  },
  {
    cat: "Milkshakes",
    items: [
      { n: "Kreamshakes", p: 75, d: "Available in 5 shot glasses", g: ["shakeFlav", "shakeX"] },
      { n: "Gourmet Kreamshakes", p: 75, d: "Available in 5 shot glasses", g: ["gShakeFlav", "shakeX"] },
    ],
  },
  {
    cat: "Frappes", note: "Powder-based iced drinks",
    items: [
      { n: "Coffee Frappe", p: 75 }, { n: "Mocha Frappe", p: 75 }, { n: "Caramel Nut Frappe", p: 75 },
      { n: "Iced Karak", p: 75 }, { n: "S'mores Frappe", p: 75 }, { n: "Rose Frappe", p: 75 },
      { n: "Saffron Frozen Custard", p: 90 },
    ],
  },
  {
    cat: "Iced Drinks", note: "Espresso-based, for coffee lovers",
    items: [
      { n: "Iced Coffee", p: 75, d: "Espresso, ice, hint of vanilla syrup" },
      { n: "Iced Mocha", p: 75, d: "Espresso, chocolate, milk over ice" },
      { n: "Iced Latte", p: 75, d: "Latte poured over ice" },
      { n: "Flavoured Iced Latte", p: 75, d: "Add your flavour in the notes" },
    ],
  },
  {
    cat: "Granitas", note: "Crushed-ice blends",
    items: [
      { n: "Cucumber Mint", p: 80 }, { n: "Passion Fruit & Orange", p: 80 }, { n: "Watermelon Fresher", p: 80 },
      { n: "Litchi & Pineapple", p: 80 }, { n: "Cranberry & Rose", p: 80 }, { n: "Red Bull Float", p: 80 },
    ],
  },
  {
    cat: "Mocktails",
    items: [
      { n: "Abu Dhabi Rose Passion", p: 85, d: "Fresh strawberry & cucumber, hints of rose essence" },
      { n: "Green Passion", p: 85, d: "Exotic blend of mango & lime" },
    ],
  },
  {
    cat: "Coffee", note: "Ethiopian Sidamo & Colombian blend, roasted weekly",
    items: [
      { n: "Latte", v: [["Short 250ml", 40], ["Tall 350ml", 45]] },
      { n: "World Famous Cappuccino", v: [["Short 250ml", 40], ["Tall 350ml", 45]], g: ["milkX"] },
      { n: "Flat White / Double Short Latte", p: 45 },
      { n: "Africano", v: [["Short 250ml", 35], ["Tall 350ml", 40]] },
      { n: "Mochachino", v: [["Short 250ml", 50], ["Tall 350ml", 55]], g: ["milkX"] },
      { n: "Café Breve", p: 60, d: "Espresso, half steamed milk, half pouring cream" },
      { n: "Espresso", v: [["Single", 30], ["Double", 35]] },
      { n: "Macchiato", v: [["Single", 30], ["Double", 35]], d: "Espresso with foam" },
      { n: "Conpana", v: [["Single", 35], ["Double", 40]], d: "Espresso with whipped cream" },
    ],
  },
  {
    cat: "Gourmet Coffee",
    items: [
      { n: "Crème Brûlée Latte", v: [["Short 250ml", 70], ["Tall 350ml", 75]] },
      { n: "Caramel Latte", v: [["Short 250ml", 70], ["Tall 350ml", 75]] },
      { n: "Hazelnut Latte", v: [["Short 250ml", 70], ["Tall 350ml", 75]] },
      { n: "Vanilla Latte", v: [["Short 250ml", 70], ["Tall 350ml", 75]] },
      { n: "Ginger Bread Latte", v: [["Short 250ml", 70], ["Tall 350ml", 75]] },
      { n: "Honey Nut Latte", v: [["Short 250ml", 70], ["Tall 350ml", 75]] },
      { n: "Spanish Saffron Latte", p: 95 },
    ],
  },
  {
    cat: "Hot Chocolates & Shots",
    items: [
      { n: "Classic Hot Chocolate", p: 70 },
      { n: "Hot Chocolate", v: [["Turkish Delight", 90], ["Lindor", 90], ["Nutella", 90], ["Kinder", 90], ["Miss Le Kreamery", 90]] },
      { n: "Dessert Shot", v: [["Milo", 40], ["Karak", 40], ["Kinder", 50], ["Lindor", 50]] },
    ],
  },
  {
    cat: "Teas",
    items: [
      { n: "Signature Karak", p: 65 },
      { n: "Five Roses", p: 35 },
      { n: "Rooibos", p: 35 },
    ],
  },
];

/* ---------------------- POS ADAPTER LAYER -----------------------
   Interface every adapter must implement:
     openTab(table) -> tab       getTab(table) -> tab | null
     addLines(table, lines)      requestBill(table)
     closeBill(table)            recordPayment(table, method)
     payLines(table, ids, method)  listTabs() -> tab[]
     subscribe(fn) -> unsubscribe
   A GAAPAdapter / LightspeedAdapter implements the same contract
   against the venue's real till. The UI never changes.            */
const newLineId = () => `${Date.now()}${Math.random().toString(36).slice(2, 6)}`;
const freshTab = (table) => ({ table, lines: [], status: "open", openedAt: Date.now(), paidVia: null });

/* SUPABASE ADAPTER — real cross-device sync.
   Every device reads and writes the same `tabs` table and subscribes
   to realtime changes, so an order on a phone appears at the till
   instantly. Active only when both keys in supabaseConfig.js are set. */
class SupabaseAdapter {
  constructor(url, key) {
    this.cache = new Map();
    this.listeners = new Set();
    this.sb = createClient(url, key);
    this._init();
  }
  emit() { this.listeners.forEach((f) => f()); }
  subscribe(fn) { this.listeners.add(fn); return () => this.listeners.delete(fn); }
  async _init() {
    try {
      const { data } = await this.sb.from("tabs").select("*");
      (data || []).forEach((r) => this.cache.set(Number(r.table_no), r.data));
      this.emit();
    } catch (e) { console.error("Supabase initial load failed:", e); }
    this.sb
      .channel("tabs-realtime")
      .on("postgres_changes", { event: "*", schema: "public", table: "tabs" }, (p) => {
        if (p.eventType === "DELETE") { if (p.old?.table_no != null) this.cache.delete(Number(p.old.table_no)); }
        else if (p.new) { this.cache.set(Number(p.new.table_no), p.new.data); }
        this.emit();
      })
      .subscribe();
  }
  async _save(table, tab) {
    this.cache.set(table, tab);
    this.emit(); // optimistic — realtime echo reconciles other devices
    try { await this.sb.from("tabs").upsert({ table_no: table, data: tab, updated_at: new Date().toISOString() }); }
    catch (e) { console.error("Supabase save failed:", e); }
  }
  openTab(table) {
    let tab = this.cache.get(table);
    if (!tab) { tab = freshTab(table); this._save(table, tab); }
    return tab;
  }
  getTab(table) { return this.cache.get(table) || null; }
  addLines(table, lines) {
    const tab = this.cache.get(table) || freshTab(table);
    if (tab.status === "paid") return;
    lines.forEach((l) => tab.lines.push({ ...l, id: newLineId(), at: Date.now() }));
    if (tab.status === "closed" || tab.status === "bill_requested") tab.status = "open";
    this._save(table, { ...tab });
  }
  requestBill(table) { const t = this.cache.get(table); if (t && t.status === "open") this._save(table, { ...t, status: "bill_requested" }); }
  closeBill(table) { const t = this.cache.get(table); if (t) this._save(table, { ...t, status: "closed" }); }
  reopen(table) { const t = this.cache.get(table); if (t && t.status !== "paid") this._save(table, { ...t, status: "open" }); }
  recordPayment(table, method) { const t = this.cache.get(table); if (t) this._save(table, { ...t, status: "paid", paidVia: method }); }
  payLines(table, lineIds, method) {
    const t = this.cache.get(table); if (!t) return;
    const ids = new Set(lineIds);
    const lines = t.lines.map((l) => (ids.has(l.id) ? { ...l, paid: true, paidVia: method } : l));
    const allPaid = lines.length > 0 && lines.every((l) => l.paid);
    this._save(table, { ...t, lines, status: allPaid ? "paid" : t.status, paidVia: allPaid ? "Split payment" : t.paidVia });
  }
  async clearTab(table) {
    this.cache.delete(table); this.emit();
    try { await this.sb.from("tabs").delete().eq("table_no", table); } catch (e) { console.error(e); }
  }
  listTabs() { return [...this.cache.values()]; }
}

/* LOCAL ADAPTER — no-backend fallback. Uses localStorage so state
   survives refresh, and BroadcastChannel so multiple tabs in the SAME
   browser sync live. (Cross-device needs Supabase — see README.)      */
class LocalAdapter {
  constructor() {
    this.KEY = "lk_tabs_v1";
    this.listeners = new Set();
    this.bc = typeof BroadcastChannel !== "undefined" ? new BroadcastChannel("lk_tabs") : null;
    if (this.bc) this.bc.onmessage = () => this.emit();
    if (typeof window !== "undefined") window.addEventListener("storage", (e) => { if (e.key === this.KEY) this.emit(); });
  }
  emit() { this.listeners.forEach((f) => f()); }
  subscribe(fn) { this.listeners.add(fn); return () => this.listeners.delete(fn); }
  _read() {
    try { return new Map(Object.entries(JSON.parse(localStorage.getItem(this.KEY) || "{}")).map(([k, v]) => [Number(k), v])); }
    catch { return new Map(); }
  }
  _write(m) {
    const obj = {}; m.forEach((v, k) => (obj[k] = v));
    try { localStorage.setItem(this.KEY, JSON.stringify(obj)); } catch {}
    if (this.bc) this.bc.postMessage(1);
    this.emit();
  }
  openTab(table) { const m = this._read(); if (!m.has(table)) { m.set(table, freshTab(table)); this._write(m); } return m.get(table); }
  getTab(table) { return this._read().get(table) || null; }
  addLines(table, lines) {
    const m = this._read(); const t = m.get(table) || freshTab(table);
    if (t.status === "paid") return;
    lines.forEach((l) => t.lines.push({ ...l, id: newLineId(), at: Date.now() }));
    if (t.status === "closed" || t.status === "bill_requested") t.status = "open";
    m.set(table, t); this._write(m);
  }
  requestBill(table) { const m = this._read(); const t = m.get(table); if (t && t.status === "open") { t.status = "bill_requested"; m.set(table, t); this._write(m); } }
  closeBill(table) { const m = this._read(); const t = m.get(table); if (t) { t.status = "closed"; m.set(table, t); this._write(m); } }
  reopen(table) { const m = this._read(); const t = m.get(table); if (t && t.status !== "paid") { t.status = "open"; m.set(table, t); this._write(m); } }
  recordPayment(table, method) { const m = this._read(); const t = m.get(table); if (t) { t.status = "paid"; t.paidVia = method; m.set(table, t); this._write(m); } }
  payLines(table, lineIds, method) {
    const m = this._read(); const t = m.get(table); if (!t) return;
    const ids = new Set(lineIds);
    t.lines = t.lines.map((l) => (ids.has(l.id) ? { ...l, paid: true, paidVia: method } : l));
    if (t.lines.length > 0 && t.lines.every((l) => l.paid)) { t.status = "paid"; t.paidVia = "Split payment"; }
    m.set(table, t); this._write(m);
  }
  clearTab(table) { const m = this._read(); m.delete(table); this._write(m); }
  listTabs() { return [...this._read().values()]; }
}

const SYNC_ON = Boolean(SUPABASE_URL && SUPABASE_ANON_KEY);
const POS = SYNC_ON ? new SupabaseAdapter(SUPABASE_URL, SUPABASE_ANON_KEY) : new LocalAdapter();
function useTabs() {
  return useSyncExternalStore(
    (fn) => POS.subscribe(fn),
    () => JSON.stringify(POS.listTabs())
  );
}

/* Payment stub — replace with Yoco SDK (Apple Pay + card).
   See README: yoco.showPopup / Checkout API goes here.            */
function payWithProvider(method) {
  return new Promise((res) => setTimeout(() => res({ ok: true, method }), 1400));
}

/* --------------------------- HELPERS ---------------------------- */
const R = (n) => `R${n.toFixed(0)}`;
const lineTotal = (l) => (l.unit + l.opts.reduce((s, o) => s + o.price, 0)) * l.qty;
const tabTotal = (t) => t.lines.reduce((s, l) => s + lineTotal(l), 0);
const paidTotal = (t) => t.lines.filter((l) => l.paid).reduce((s, l) => s + lineTotal(l), 0);
const remainingTotal = (t) => tabTotal(t) - paidTotal(t);
const unpaidLines = (t) => t.lines.filter((l) => !l.paid);
const itemBase = (it) => (it.v ? it.v[0][1] : it.p || 0);

/* ============================ APP =============================== */
export default function App() {
  const [view, setView] = useState("landing"); // landing | order | till
  const [table, setTable] = useState(null);

  return (
    <div className="min-h-screen" style={{ background: T.paper, color: T.ink, fontFamily: "'Jost','Poppins',system-ui,sans-serif" }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Jost:wght@400;500;600;700&display=swap');
        *::-webkit-scrollbar{display:none} *{scrollbar-width:none}
        @media (prefers-reduced-motion: reduce){*{transition:none!important;animation:none!important}}
        .sheet{animation:up .25s ease} @keyframes up{from{transform:translateY(24px);opacity:.4}to{transform:translateY(0);opacity:1}}
      `}</style>
      {view === "landing" && <Landing onTable={(t) => { setTable(t); POS.openTab(t); setView("order"); }} onTill={() => setView("till")} />}
      {view === "order" && table != null && <Customer table={table} onExit={() => setView("landing")} />}
      {view === "till" && <Till onExit={() => setView("landing")} />}
    </div>
  );
}

/* --------------------------- LANDING ---------------------------- */
function Landing({ onTable, onTill }) {
  return (
    <div className="max-w-md mx-auto min-h-screen flex flex-col px-6 py-10">
      <div className="text-center mt-8">
        <div className="text-xs tracking-widest uppercase" style={{ color: T.sub }}>Gourmet Eatery · Pizzeria · Dessert &amp; Coffee Lounge</div>
        <h1 className="text-5xl font-bold mt-3" style={goldText}>Le Kreamery.</h1>
        <p className="mt-3 text-sm" style={{ color: T.sub }}>
          Scan the code on your table to open your bill, order as you go, and pay when you're done. This screen simulates the scan — choose your table.
        </p>
      </div>
      <div className="grid grid-cols-4 gap-3 mt-10">
        {Array.from({ length: 12 }, (_, i) => i + 1).map((t) => (
          <button key={t} onClick={() => onTable(t)}
            className="rounded-2xl py-5 text-lg font-semibold bg-white shadow-sm hover:shadow transition"
            style={{ border: `1px solid ${T.line}` }}>
            {t}
          </button>
        ))}
      </div>
      <div className="text-center text-xs mt-6" style={{ color: T.sub }}>All menu items strictly Halaal.</div>
      <div className="mt-auto pt-10 text-center">
        <button onClick={onTill} className="text-xs underline" style={{ color: T.sub }}>Staff · open the till view</button>
        <div className="mt-3 text-[11px]" style={{ color: T.sub }}>
          {SYNC_ON
            ? <span><span style={{ color: T.ok }}>●</span> Live sync on — orders update across all devices</span>
            : <span><span style={{ color: T.warn }}>●</span> Local mode — add Supabase keys for cross-device sync</span>}
        </div>
      </div>
    </div>
  );
}

/* -------------------------- CUSTOMER ---------------------------- */
function Customer({ table, onExit }) {
  useTabs();
  const tab = POS.getTab(table) || POS.openTab(table);
  const [screen, setScreen] = useState("menu"); // menu | tab | pay | done
  const [activeCat, setActiveCat] = useState(MENU[0].cat);
  const [openItem, setOpenItem] = useState(null);
  const [query, setQuery] = useState("");

  const filtered = useMemo(() => {
    if (!query.trim()) return MENU;
    const q = query.toLowerCase();
    return MENU.map((c) => ({ ...c, items: c.items.filter((i) => (i.n + " " + (i.d || "")).toLowerCase().includes(q)) })).filter((c) => c.items.length);
  }, [query]);

  const count = tab.lines.reduce((s, l) => s + l.qty, 0);
  const total = tabTotal(tab);

  useEffect(() => { if (tab.status === "paid") setScreen("done"); }, [tab.status]);

  if (screen === "done") return <ThankYou table={table} onExit={() => { POS.clearTab(table); onExit(); }} />;

  return (
    <div className="max-w-md mx-auto min-h-screen flex flex-col relative">
      {/* header */}
      <header className="sticky top-0 z-20 px-5 pt-5 pb-3" style={{ background: T.paper }}>
        <div className="flex items-end justify-between">
          <div>
            <div className="text-2xl font-bold leading-none" style={goldText}>Le Kreamery.</div>
            <div className="text-xs mt-1" style={{ color: T.sub }}>Table {table} · bill open</div>
          </div>
          <button onClick={onExit} className="text-xs underline" style={{ color: T.sub }}>exit</button>
        </div>
        {screen === "menu" && (
          <>
            <input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Search the menu"
              className="mt-3 w-full rounded-xl px-4 py-2 text-sm bg-white outline-none" style={{ border: `1px solid ${T.line}` }} />
            <nav className="flex gap-2 overflow-x-auto mt-3 -mx-5 px-5">
              {MENU.map((c) => (
                <a key={c.cat} href={`#cat-${c.cat}`} onClick={() => setActiveCat(c.cat)}
                  className="whitespace-nowrap text-xs font-semibold px-3 py-2 rounded-full transition"
                  style={activeCat === c.cat ? { background: T.dark, color: "#fff" } : { background: "#fff", color: T.ink, border: `1px solid ${T.line}` }}>
                  {c.cat}
                </a>
              ))}
            </nav>
          </>
        )}
      </header>

      {/* body */}
      {screen === "menu" && (
        <main className="flex-1 px-5 pb-36">
          {filtered.map((c) => (
            <section key={c.cat} id={`cat-${c.cat}`} className="pt-7">
              <h2 className="text-3xl font-bold" style={goldText}>{c.cat}.</h2>
              {c.note && <div className="text-xs mt-1" style={{ color: T.sub }}>{c.note}</div>}
              <div className="mt-3 space-y-2">
                {c.items.map((it) => (
                  <button key={it.n} onClick={() => setOpenItem(it)}
                    className="w-full text-left bg-white rounded-2xl px-4 py-3 shadow-sm hover:shadow transition"
                    style={{ border: `1px solid ${T.line}` }}>
                    <div className="flex justify-between gap-3">
                      <div className="font-semibold text-sm">{it.n}</div>
                      <div className="font-semibold text-sm shrink-0" style={{ color: T.gold2 }}>
                        {it.v ? `from ${R(Math.min(...it.v.map((v) => v[1])))}` : R(it.p)}
                      </div>
                    </div>
                    {it.d && <div className="text-xs mt-1 leading-snug" style={{ color: T.sub }}>{it.d}</div>}
                  </button>
                ))}
              </div>
            </section>
          ))}
          <FooterNotes />
        </main>
      )}

      {screen === "tab" && <TabView table={table} onBack={() => setScreen("menu")} onPay={() => setScreen("pay")} />}
      {screen === "pay" && <PayView table={table} onBack={() => setScreen("tab")} />}

      {/* bill bar */}
      {screen === "menu" && count > 0 && (
        <button onClick={() => setScreen("tab")}
          className="fixed bottom-4 left-1/2 -translate-x-1/2 w-11/12 max-w-sm rounded-2xl py-4 px-5 flex justify-between items-center text-white font-semibold shadow-lg"
          style={{ background: T.dark }}>
          <span className="text-sm">View my bill · {count} item{count > 1 ? "s" : ""}</span>
          <span>{R(total)}</span>
        </button>
      )}

      {openItem && <ItemSheet item={openItem} onClose={() => setOpenItem(null)} onAdd={(line) => { POS.addLines(table, [line]); setOpenItem(null); }} />}
    </div>
  );
}

/* ------------------------- ITEM SHEET --------------------------- */
function ItemSheet({ item, onClose, onAdd }) {
  const groups = (item.g || []).map((k) => ({ key: k, ...G[k] }));
  const [variant, setVariant] = useState(item.v ? 0 : null);
  const [singles, setSingles] = useState(() => Object.fromEntries(groups.filter((g) => g.type === "single").map((g) => [g.key, null])));
  const [multis, setMultis] = useState({});
  const [qty, setQty] = useState(1);
  const [notes, setNotes] = useState("");

  const unit = item.v ? item.v[variant][1] : item.p;
  const opts = [];
  if (item.v) opts.push({ group: "Option", name: item.v[variant][0], price: 0 });
  groups.forEach((g) => {
    if (g.type === "single" && singles[g.key] != null) {
      const [n, p] = g.options[singles[g.key]];
      opts.push({ group: g.name, name: n, price: p });
    }
  });
  Object.entries(multis).forEach(([k, v]) => { if (v) { const [gk, idx] = k.split("|"); const src = gk === "x" ? item.x : G[gk].options; const [n, p] = src[+idx]; opts.push({ group: gk === "x" ? "Extra" : G[gk].name, name: n, price: p }); } });

  const missing = groups.filter((g) => g.type === "single" && singles[g.key] == null);
  const total = (unit + opts.reduce((s, o) => s + o.price, 0)) * qty;

  return (
    <div className="fixed inset-0 z-30 flex items-end justify-center" style={{ background: "rgba(20,20,25,.45)" }} onClick={onClose}>
      <div className="sheet w-full max-w-md bg-white rounded-t-3xl max-h-full overflow-y-auto" onClick={(e) => e.stopPropagation()}>
        <div className="px-5 pt-5 pb-32">
          <div className="flex justify-between gap-4">
            <div>
              <div className="text-lg font-bold">{item.n}</div>
              {item.d && <div className="text-xs mt-1" style={{ color: T.sub }}>{item.d}</div>}
            </div>
            <button onClick={onClose} className="w-8 h-8 rounded-full shrink-0 text-sm" style={{ background: T.paper }}>✕</button>
          </div>

          {item.v && (
            <OptBlock title="Choose one" required>
              {item.v.map(([n, p], i) => (
                <Row key={n} label={n} price={p ? R(p) : ""} on={variant === i} onClick={() => setVariant(i)} radio />
              ))}
            </OptBlock>
          )}

          {groups.map((g) => (
            <OptBlock key={g.key} title={g.name} required={g.type === "single"}>
              {g.options.map(([n, p], i) =>
                g.type === "single" ? (
                  <Row key={n} label={n} price={p ? `+${R(p)}` : ""} on={singles[g.key] === i} onClick={() => setSingles({ ...singles, [g.key]: i })} radio />
                ) : (
                  <Row key={n} label={n} price={`+${R(p)}`} on={!!multis[`${g.key}|${i}`]} onClick={() => setMultis({ ...multis, [`${g.key}|${i}`]: !multis[`${g.key}|${i}`] })} />
                )
              )}
            </OptBlock>
          ))}

          {item.x && (
            <OptBlock title="Add extras">
              {item.x.map(([n, p], i) => (
                <Row key={n} label={n} price={`+${R(p)}`} on={!!multis[`x|${i}`]} onClick={() => setMultis({ ...multis, [`x|${i}`]: !multis[`x|${i}`] })} />
              ))}
            </OptBlock>
          )}

          <OptBlock title="Anything the kitchen should know?">
            <textarea value={notes} onChange={(e) => setNotes(e.target.value)} rows={2} placeholder="e.g. no onions, sauce on the side"
              className="w-full rounded-xl p-3 text-sm outline-none" style={{ border: `1px solid ${T.line}` }} />
          </OptBlock>
        </div>

        <div className="fixed bottom-0 left-1/2 -translate-x-1/2 w-full max-w-md bg-white px-5 py-4 flex items-center gap-4" style={{ borderTop: `1px solid ${T.line}` }}>
          <div className="flex items-center gap-3 rounded-xl px-3 py-2" style={{ border: `1px solid ${T.line}` }}>
            <button onClick={() => setQty(Math.max(1, qty - 1))} className="text-lg font-bold w-5">−</button>
            <span className="font-semibold w-4 text-center">{qty}</span>
            <button onClick={() => setQty(qty + 1)} className="text-lg font-bold w-5">+</button>
          </div>
          <button
            disabled={missing.length > 0}
            onClick={() => onAdd({ name: item.n, unit, qty, opts, notes: notes.trim() })}
            className="flex-1 rounded-xl py-3 font-semibold text-white text-sm disabled:opacity-40"
            style={{ background: T.dark }}>
            {missing.length ? `Choose: ${missing[0].name.replace("Choose your ", "").replace("Choose ", "")}` : `Add to bill · ${R(total)}`}
          </button>
        </div>
      </div>
    </div>
  );
}
function OptBlock({ title, required, children }) {
  return (
    <div className="mt-5">
      <div className="flex items-center gap-2">
        <div className="text-xs font-bold uppercase tracking-wide">{title}</div>
        {required && <span className="text-xs px-2 py-0.5 rounded-full text-white" style={{ background: T.amber }}>required</span>}
      </div>
      <div className="mt-2 rounded-2xl overflow-hidden" style={{ border: `1px solid ${T.line}` }}>{children}</div>
    </div>
  );
}
function Row({ label, price, on, onClick, radio }) {
  return (
    <button onClick={onClick} className="w-full flex items-center justify-between px-4 py-3 text-sm bg-white" style={{ borderBottom: `1px solid ${T.paper}` }}>
      <span className="flex items-center gap-3 text-left">
        <span className={`inline-block w-4 h-4 ${radio ? "rounded-full" : "rounded"} border`} style={{ borderColor: on ? T.gold2 : "#cbd0d6", background: on ? T.gold2 : "#fff" }} />
        {label}
      </span>
      <span style={{ color: T.amber }} className="font-semibold">{price}</span>
    </button>
  );
}

/* --------------------------- TAB VIEW --------------------------- */
function TabView({ table, onBack, onPay }) {
  useTabs();
  const tab = POS.getTab(table);
  if (!tab) return null;
  const total = tabTotal(tab);
  const paid = paidTotal(tab);
  const remaining = remainingTotal(tab);
  return (
    <main className="flex-1 px-5 pb-10">
      <h2 className="text-3xl font-bold pt-4" style={goldText}>My Bill.</h2>
      <div className="text-xs mt-1" style={{ color: T.sub }}>Table {table}</div>

      <div className="mt-4 bg-white rounded-2xl p-4 space-y-3" style={{ border: `1px solid ${T.line}` }}>
        {tab.lines.length === 0 && <div className="text-sm" style={{ color: T.sub }}>Nothing on the bill yet — your order will appear here the moment you add it.</div>}
        {tab.lines.map((l) => (
          <div key={l.id} className="flex justify-between gap-3 text-sm" style={{ borderBottom: `1px dashed ${T.line}`, paddingBottom: 8, opacity: l.paid ? 0.5 : 1 }}>
            <div>
              <div className="font-semibold flex items-center gap-2">
                {l.qty} × {l.name}
                {l.paid && <span className="text-[10px] font-bold px-2 py-0.5 rounded-full text-white" style={{ background: T.ok }}>PAID</span>}
              </div>
              {l.opts.filter((o) => o.group !== "Option" || o.name).map((o, i) => (
                <div key={i} className="text-xs" style={{ color: T.sub }}>{o.name}{o.price ? ` (+${R(o.price)})` : ""}</div>
              ))}
              {l.notes && <div className="text-xs italic" style={{ color: T.amber }}>“{l.notes}”</div>}
            </div>
            <div className="font-semibold shrink-0">{R(lineTotal(l))}</div>
          </div>
        ))}
        {paid > 0 && (
          <div className="flex justify-between text-sm" style={{ color: T.ok }}>
            <span>Paid so far</span><span>−{R(paid)}</span>
          </div>
        )}
        <div className="flex justify-between font-bold pt-1">
          <span>{paid > 0 ? "Remaining" : "Total"}</span><span>{R(paid > 0 ? remaining : total)}</span>
        </div>
        <div className="text-xs" style={{ color: T.sub }}>10% service charge applies to tables of 10 or more — added at the till.</div>
      </div>

      {tab.status === "open" && (
        <>
          <button onClick={onBack} className="mt-4 w-full rounded-xl py-3 font-semibold text-sm bg-white" style={{ border: `1px solid ${T.line}` }}>Order more</button>
          <button onClick={() => POS.requestBill(table)} disabled={!tab.lines.length}
            className="mt-2 w-full rounded-xl py-3 font-semibold text-sm text-white disabled:opacity-40" style={{ background: T.dark }}>
            We're done — request the bill
          </button>
        </>
      )}
      {tab.status === "bill_requested" && (
        <div className="mt-4 rounded-2xl p-4 text-sm" style={{ background: "#fff7ea", border: `1px solid ${T.amber}` }}>
          Your waitron has been notified and will close your bill shortly. You can still order more if you change your mind.
          <button onClick={onBack} className="mt-3 w-full rounded-xl py-2 font-semibold text-sm bg-white" style={{ border: `1px solid ${T.line}` }}>Back to menu</button>
        </div>
      )}
      {tab.status === "closed" && (
        <>
          <div className="mt-4 rounded-2xl p-4 text-sm" style={{ background: "#eefaf2", border: `1px solid ${T.ok}` }}>
            Your bill is closed. Pay your whole share or just your items — split it however you like, here or at the till.
          </div>
          <button onClick={onPay} className="mt-3 w-full rounded-xl py-3 font-semibold text-sm text-white" style={{ background: T.dark }}>
            Pay or split · {R(remaining)} left
          </button>
        </>
      )}
    </main>
  );
}

/* --------------------------- PAY VIEW ---------------------------
   Split by item: each person selects the items they had and pays
   just those. Paid items drop off; the tab settles fully only once
   every item is paid.                                               */
function PayView({ table, onBack }) {
  useTabs();
  const tab = POS.getTab(table);
  const [busy, setBusy] = useState(null);
  const [sel, setSel] = useState(() => new Set());
  const [justPaid, setJustPaid] = useState(null);
  if (!tab) return null;

  const open = unpaidLines(tab);
  const alreadyPaid = paidTotal(tab);
  const remaining = remainingTotal(tab);
  const selected = open.filter((l) => sel.has(l.id));
  const selectedTotal = selected.reduce((s, l) => s + lineTotal(l), 0);

  const toggle = (id) => { const n = new Set(sel); n.has(id) ? n.delete(id) : n.add(id); setSel(n); };
  const payingAll = sel.size === open.length && open.length > 0;

  const pay = async (method) => {
    if (sel.size === 0) return;
    setBusy(method);
    const amt = selectedTotal, ids = [...sel];
    const r = await payWithProvider(method); // ← Yoco SDK call goes here
    if (r.ok) { POS.payLines(table, ids, method); setJustPaid(amt); setSel(new Set()); }
    setBusy(null);
  };

  // Paid a portion, but others still owe — per-person confirmation.
  if (justPaid != null && remaining > 0) {
    return (
      <main className="flex-1 px-5 pb-10 flex flex-col items-center justify-center text-center min-h-[70vh]">
        <div className="text-4xl">✓</div>
        <h2 className="text-3xl font-bold mt-3" style={goldText}>Your share is paid.</h2>
        <p className="text-sm mt-3" style={{ color: T.sub }}>
          {R(justPaid)} settled. There's still {R(remaining)} on the table for the rest of your group to pay — they can settle their items here or at the till.
        </p>
        <button onClick={() => setJustPaid(null)} className="mt-6 rounded-xl px-6 py-3 text-sm font-semibold text-white" style={{ background: T.dark }}>Pay another share</button>
        <button onClick={onBack} className="mt-2 text-xs underline" style={{ color: T.sub }}>Back to the bill</button>
      </main>
    );
  }
  if (open.length === 0) {
    return (
      <main className="flex-1 px-5 pb-10 flex flex-col items-center justify-center text-center min-h-[70vh]">
        <div className="text-3xl">✓</div>
        <h2 className="text-2xl font-bold mt-3" style={goldText}>This bill is fully settled.</h2>
        <button onClick={onBack} className="mt-6 text-xs underline" style={{ color: T.sub }}>Back to the bill</button>
      </main>
    );
  }

  return (
    <main className="flex-1 px-5 pb-40">
      <h2 className="text-3xl font-bold pt-4" style={goldText}>Pay.</h2>
      <div className="text-xs mt-1" style={{ color: T.sub }}>Table {table}</div>

      {alreadyPaid > 0 && (
        <div className="mt-3 rounded-xl px-4 py-2 text-xs" style={{ background: "#eefaf2", border: `1px solid ${T.ok}`, color: T.ink }}>
          {R(alreadyPaid)} already paid by your table · {R(remaining)} still to go
        </div>
      )}

      <div className="flex items-center justify-between mt-5">
        <div className="text-xs font-bold uppercase tracking-wide">Choose what you're paying for</div>
        <button onClick={() => setSel(payingAll ? new Set() : new Set(open.map((l) => l.id)))}
          className="text-xs font-semibold underline" style={{ color: T.gold2 }}>
          {payingAll ? "Clear" : "Select everything"}
        </button>
      </div>

      <div className="mt-2 rounded-2xl overflow-hidden" style={{ border: `1px solid ${T.line}` }}>
        {open.map((l) => {
          const on = sel.has(l.id);
          return (
            <button key={l.id} onClick={() => toggle(l.id)} className="w-full flex items-center justify-between gap-3 px-4 py-3 text-sm bg-white text-left" style={{ borderBottom: `1px solid ${T.paper}` }}>
              <span className="flex items-start gap-3">
                <span className="inline-block w-4 h-4 rounded border mt-0.5 shrink-0" style={{ borderColor: on ? T.gold2 : "#cbd0d6", background: on ? T.gold2 : "#fff" }} />
                <span>
                  <span className="font-semibold">{l.qty} × {l.name}</span>
                  {l.notes && <span className="block text-xs italic" style={{ color: T.amber }}>“{l.notes}”</span>}
                </span>
              </span>
              <span className="font-semibold shrink-0">{R(lineTotal(l))}</span>
            </button>
          );
        })}
      </div>

      <div className="fixed bottom-0 left-1/2 -translate-x-1/2 w-full max-w-md bg-white px-5 py-4 space-y-2" style={{ borderTop: `1px solid ${T.line}` }}>
        <div className="flex justify-between text-sm font-bold">
          <span>{payingAll ? "Paying the whole bill" : sel.size ? `Paying for ${sel.size} item${sel.size > 1 ? "s" : ""}` : "Select your items"}</span>
          <span>{R(selectedTotal)}</span>
        </div>
        <button onClick={() => pay("Apple Pay")} disabled={!!busy || sel.size === 0}
          className="w-full rounded-xl py-3.5 font-semibold text-white disabled:opacity-40" style={{ background: "#000" }}>
          {busy === "Apple Pay" ? "Confirming…" : ` Pay ${R(selectedTotal)} with Apple Pay`}
        </button>
        <button onClick={() => pay("Card")} disabled={!!busy || sel.size === 0}
          className="w-full rounded-xl py-3.5 font-semibold bg-white disabled:opacity-40" style={{ border: `1px solid ${T.line}` }}>
          {busy === "Card" ? "Confirming…" : "Pay with card"}
        </button>
        <button onClick={onBack} className="w-full text-center text-xs underline" style={{ color: T.sub }}>Back to my bill</button>
      </div>
    </main>
  );
}

function ThankYou({ table, onExit }) {
  return (
    <div className="max-w-md mx-auto min-h-screen flex flex-col items-center justify-center px-8 text-center">
      <div className="text-4xl">☕</div>
      <h2 className="text-4xl font-bold mt-4" style={goldText}>Shukran.</h2>
      <p className="text-sm mt-3" style={{ color: T.sub }}>Table {table} is settled. We'd love to see you again — tag us #MyLeKreamery.</p>
      <button onClick={onExit} className="mt-8 rounded-xl px-6 py-3 text-sm font-semibold text-white" style={{ background: T.dark }}>Done</button>
    </div>
  );
}

function FooterNotes() {
  return (
    <div className="text-xs mt-10 leading-relaxed" style={{ color: T.sub }}>
      All menu items strictly Halaal. Most products may contain nuts or traces of: milk, wheat (gluten), eggs, soybean, sunflower, sesame — ask staff about allergens before ordering. Prices and products vary by store. 10% service charge applies to tables of 10 or more.
      <div className="mt-2">Eldo Square, Pretoria · Atlas Junction, Benoni · Oxford Centre, Johannesburg</div>
    </div>
  );
}

/* ---------------------------- TILL ------------------------------ */
function Till({ onExit }) {
  useTabs();
  const [sel, setSel] = useState(null);
  const tabs = POS.listTabs().sort((a, b) => a.table - b.table);
  const active = sel != null ? POS.getTab(sel) : null;
  const badge = (s) =>
    s === "open" ? { t: "OPEN", c: "#3b82f6" } :
    s === "bill_requested" ? { t: "BILL REQUESTED", c: T.warn } :
    s === "closed" ? { t: "AWAITING PAYMENT", c: T.gold2 } : { t: "PAID", c: T.ok };

  return (
    <div className="min-h-screen text-white" style={{ background: T.dark }}>
      <div className="max-w-3xl mx-auto px-5 py-6">
        <div className="flex items-end justify-between">
          <div>
            <div className="text-2xl font-bold" style={goldText}>Le Kreamery.</div>
            <div className="text-xs mt-1 opacity-60">Till · live table tabs (this screen is what the waitron sees)</div>
          </div>
          <button onClick={onExit} className="text-xs underline opacity-60">exit</button>
        </div>

        {tabs.length === 0 && (
          <div className="mt-16 text-center opacity-60 text-sm">No open tabs yet. When a guest scans a table code and orders, it appears here instantly.</div>
        )}

        <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 mt-6">
          {tabs.map((t) => {
            const b = badge(t.status);
            return (
              <button key={t.table} onClick={() => setSel(t.table)}
                className="rounded-2xl p-4 text-left transition hover:opacity-90"
                style={{ background: "#232529", border: sel === t.table ? `1px solid ${T.gold1}` : "1px solid #2f3238" }}>
                <div className="flex justify-between items-center">
                  <div className="text-lg font-bold">Table {t.table}</div>
                  <div className="text-xs font-bold px-2 py-1 rounded-full" style={{ background: b.c }}>{b.t}</div>
                </div>
                <div className="text-sm opacity-70 mt-2">
                  {t.lines.reduce((s, l) => s + l.qty, 0)} items · {R(tabTotal(t))}
                  {paidTotal(t) > 0 && t.status !== "paid" && <span style={{ color: T.gold1 }}> · {R(remainingTotal(t))} left</span>}
                </div>
              </button>
            );
          })}
        </div>

        {active && (
          <div className="mt-6 rounded-2xl p-5" style={{ background: "#232529", border: "1px solid #2f3238" }}>
            <div className="flex justify-between items-center">
              <div className="font-bold">
                Table {active.table} — {R(tabTotal(active))}
                {paidTotal(active) > 0 && active.status !== "paid" && <span className="font-normal opacity-70" style={{ color: T.gold1 }}> · {R(remainingTotal(active))} outstanding</span>}
              </div>
              <button onClick={() => setSel(null)} className="text-xs underline opacity-60">close</button>
            </div>
            <div className="mt-3 space-y-2 text-sm">
              {active.lines.map((l) => (
                <div key={l.id} className="flex justify-between gap-3" style={{ borderBottom: "1px dashed #2f3238", paddingBottom: 6, opacity: l.paid ? 0.45 : 1 }}>
                  <div>
                    <div className="flex items-center gap-2">
                      {l.qty} × {l.name}
                      {l.paid && <span className="text-[10px] font-bold px-1.5 py-0.5 rounded-full" style={{ background: T.ok }}>PAID</span>}
                    </div>
                    {l.opts.map((o, i) => <div key={i} className="text-xs opacity-60">{o.name}{o.price ? ` +${R(o.price)}` : ""}</div>)}
                    {l.notes && <div className="text-xs" style={{ color: T.gold1 }}>“{l.notes}”</div>}
                  </div>
                  <div className="shrink-0">{R(lineTotal(l))}</div>
                </div>
              ))}
            </div>
            <div className="flex flex-wrap gap-2 mt-4">
              {active.status !== "paid" && active.status !== "closed" && (
                <button onClick={() => POS.closeBill(active.table)} className="rounded-xl px-4 py-2 text-sm font-semibold" style={{ background: T.gold2 }}>Close bill</button>
              )}
              {active.status === "closed" && (
                <button onClick={() => POS.reopen(active.table)} className="rounded-xl px-4 py-2 text-sm font-semibold" style={{ background: "#2f3238" }}>Reopen</button>
              )}
              {active.status !== "paid" && (
                <>
                  <button onClick={() => POS.payLines(active.table, unpaidLines(active).map((l) => l.id), "Cash at till")} className="rounded-xl px-4 py-2 text-sm font-semibold" style={{ background: T.ok }}>Settle {R(remainingTotal(active))} — cash</button>
                  <button onClick={() => POS.payLines(active.table, unpaidLines(active).map((l) => l.id), "Card at till")} className="rounded-xl px-4 py-2 text-sm font-semibold" style={{ background: T.ok }}>Settle {R(remainingTotal(active))} — card</button>
                </>
              )}
              {active.status === "paid" && (
                <>
                  <div className="text-sm opacity-70 py-2">Settled via {active.paidVia}.</div>
                  <button onClick={() => { POS.clearTab(active.table); setSel(null); }} className="rounded-xl px-4 py-2 text-sm font-semibold" style={{ background: "#2f3238" }}>Clear table</button>
                </>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

Transport Lifecycle Emissions Calculator

A MATLAB and Excel tool for calculating the full lifecycle greenhouse gas (GHG) emissions of different transport methods — built as part of my BEng dissertation, "Evaluation of carbon emissions of various transportation methods" (University of Nottingham, 2025).

What it does: The calculator quantifies emissions across 10 transport and fuel-type combinations (petrol, diesel, PHEV and EV cars; diesel, electric and biomethane buses; diesel and electric trains; underground; airplane), covering two categories of emissions:

Direct emissions — CO₂, CH₄ and N₂O produced during use, calculated using IPCC AR6 GWP100 factors
Indirect emissions — electricity generation, fuel production, vehicle manufacturing, and end-of-life disposal

Users input their transport mode, fuel type, fuel economy, distance and (for electric modes) their local electricity grid, and the tool returns a full emissions breakdown plus a lifecycle total.

Files
EmissionsCalculatorGUI.m — Interactive MATLAB GUI (built with uifigure/uigridlayout). Inputs dynamically enable/disable based on the selected transport mode and fuel type, and results are displayed with a live bar chart breakdown.

Emissions_Calculator_fixed.xlsx — Excel version of the same model, with automated calculations and linked charts, for users without access to MATLAB.

Background: The model was validated against 3 real-world case studies (short, medium and long-distance trips, including multi-leg journeys with mode changes) to compare lifecycle emissions across transport options.

Author: Amr Ayashi

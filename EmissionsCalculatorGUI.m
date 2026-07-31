function EmissionsCalculatorGUI()
    %Emissions Calculator GUI

    % Create figure & grid
    fig = uifigure('Name','GHG Emissions Calculator','Position',[100 100 600 780]);
    gl  = uigridlayout(fig,[18,2]);
    gl.RowHeight   = repmat({30},1,18);
    gl.ColumnWidth = {'1x','2x'};

    % Transport Mode
    transportLabel = uilabel(gl,'Text','Transport Mode:','HorizontalAlignment','right');
    transportLabel.Layout.Row    = 1; transportLabel.Layout.Column = 1;
    transportDD    = uidropdown(gl,'Items',{'Car','Bus','Airplane','Underground','Train'});
    transportDD.Layout.Row       = 1; transportDD.Layout.Column    = 2;

    % Fuel Type
    fuelLabel = uilabel(gl,'Text','Fuel Type:','HorizontalAlignment','right');
    fuelLabel.Layout.Row    = 2; fuelLabel.Layout.Column = 1;
    fuelDD = uidropdown(gl,'Items',{});
    fuelDD.Layout.Row       = 2; fuelDD.Layout.Column    = 2;

    % Fuel Economy / Energy Cons.
    feLabel = uilabel(gl,'Text','Fuel Economy / Energy Cons.:','HorizontalAlignment','right');
    feLabel.Layout.Row    = 3; feLabel.Layout.Column = [1 2];
    feField = uieditfield(gl,'numeric');
    feField.Layout.Row    = 4; feField.Layout.Column = [1 2];

    % Fuel Economy Unit
    unitLabel = uilabel(gl,'Text','Fuel Economy Unit:','HorizontalAlignment','right');
    unitLabel.Layout.Row    = 5; unitLabel.Layout.Column = 1;
    unitDD = uidropdown(gl,'Items',{'km/L','mpg'});
    unitDD.Layout.Row       = 5; unitDD.Layout.Column    = 2;

    % Distance
    distanceLabel = uilabel(gl,'Text','Distance (km):','HorizontalAlignment','right');
    distanceLabel.Layout.Row    = 6; distanceLabel.Layout.Column = 1;
    distanceField = uieditfield(gl,'numeric');
    distanceField.Layout.Row    = 6; distanceField.Layout.Column = 2;

    % Electricity Grid / Custom CI (EV only)
    gridLabel = uilabel(gl,'Text','Electricity Grid (Country):','HorizontalAlignment','right');
    gridLabel.Layout.Row    = 7; gridLabel.Layout.Column = 1;
    gridDD    = uidropdown(gl,'Items',{'UK','USA','Germany','France','India','China','GlobalAvg','Other'});
    gridDD.Layout.Row       = 7; gridDD.Layout.Column    = 2;

    customCIField = uieditfield(gl,'numeric','Value',125,'Enable','off');
    customCIField.Layout.Row    = 8; customCIField.Layout.Column = 2;

    carbonIntensityLabel = uilabel(gl,'Text','Carbon Intensity: 125 gCO₂/kWh');
    carbonIntensityLabel.Layout.Row    = 9; carbonIntensityLabel.Layout.Column = [1 2];

    % Calculate button
    calcButton = uibutton(gl,'Text','Calculate');
    calcButton.Layout.Row    = 10; calcButton.Layout.Column = [1 2];

    % Results area
    resultsArea = uitextarea(gl,'Editable',false);
    resultsArea.Layout.Row    = [11 14]; resultsArea.Layout.Column = [1 2];

    % Breakdown chart
    axesContainer = uiaxes(gl);
    axesContainer.Layout.Row    = [15 18]; axesContainer.Layout.Column = [1 2];

    % Callbacks
    transportDD.ValueChangedFcn    = @(~,~) toggleUI();
    fuelDD.ValueChangedFcn         = @(~,~) toggleUI();
    gridDD.ValueChangedFcn         = @(~,~) updateCI();
    customCIField.ValueChangedFcn  = @(~,~) updateCI();
    calcButton.ButtonPushedFcn     = @(~,~) calculateEmissions();

    % Initialize UI
    toggleUI();
    updateCI();

    function toggleUI()
        mode = transportDD.Value;
        % Disable all
        fuelLabel.Enable        = 'off';
        fuelDD.Enable           = 'off';
        feLabel.Enable          = 'off';
        feField.Enable          = 'off';
        unitLabel.Enable        = 'off';
        unitDD.Enable           = 'off';
        distanceField.Enable    = 'off';
        gridDD.Enable           = 'off';
        customCIField.Enable    = 'off';
        carbonIntensityLabel.Enable = 'off';

        % Enable relevant controls
        switch mode
            case 'Car'
                fuelLabel.Enable  = 'on'; fuelDD.Enable = 'on';
                feLabel.Enable    = 'on'; feField.Enable = 'on';
                unitLabel.Enable  = 'on'; unitDD.Enable = 'on';
                fuelDD.Items      = {'Petrol','Diesel','PHEV','EV'};
            case 'Bus'
                fuelLabel.Enable  = 'on'; fuelDD.Enable = 'on';
                fuelDD.Items      = {'Diesel','Electric','Biomethane'};
            case 'Train'
                fuelLabel.Enable  = 'on'; fuelDD.Enable = 'on';
                fuelDD.Items      = {'Diesel','Electric'};
        end
        distanceField.Enable = 'on';

        % Electric/EV modes need CI
        isElec = (strcmp(mode,'Car')   && any(strcmp(fuelDD.Value,{'EV','PHEV'}))) ...
               || (strcmp(mode,'Bus')   && strcmp(fuelDD.Value,'Electric'))   ...
               || (strcmp(mode,'Train') && strcmp(fuelDD.Value,'Electric')) ...
               || strcmp(mode,'Underground');
        if isElec
            gridDD.Enable = 'on';
            carbonIntensityLabel.Enable = 'on';
            if strcmp(gridDD.Value,'Other')
                customCIField.Enable = 'on';
            end
        end
    end

    function updateCI()
        presets = struct('UK',125,'USA',386,'Germany',385,'France',56,'India',643,'China',560,'GlobalAvg',450);
        if strcmp(gridDD.Value,'Other')
            CI = customCIField.Value;
        else
            CI = presets.(strrep(gridDD.Value,' ',''));
        end
        carbonIntensityLabel.Text = sprintf('Carbon Intensity: %d gCO₂/kWh',CI);
        toggleUI();
    end

    function calculateEmissions()
        %% Constants
        CH4_f   = 0.027216;  N2O_f   = 0.022494;
        GWP_CH4 = 28;        GWP_N2O = 265;
        CO2_petrol  = 2.30;  CO2_diesel  = 2.6533;  CO2_hybrid = 1.955;
        avg_eff     = [6,40];
        bus_man     = 5;     bus_eol     = 1.5;
        train_man   = 1;     train_eol   = 1.25;

        %% Inputs
        mode = transportDD.Value;
        dist = distanceField.Value;
        % Gather CI
        if strcmp(gridDD.Value,'Other')
            CI = customCIField.Value;
        else
            pm = struct('UK',125,'USA',386,'Germany',385,'France',56,'India',643,'China',560,'GlobalAvg',450);
            CI = pm.(strrep(gridDD.Value,' ',''));
        end

        %% Direct
        CO2 = 0; CH4 = 0; N2O = 0;
        switch mode
            case 'Car'
                fuel = fuelDD.Value; fe = feField.Value;
                if strcmp(unitDD.Value,'mpg'), fe = fe * 0.425144; end
                if fe==0, fe = 22.7; end
                switch fuel
                    case 'Petrol', CO2 = (dist/fe)*CO2_petrol*1000;
                    case 'Diesel', CO2 = (dist/fe)*CO2_diesel*1000;
                    case 'PHEV',   CO2 = (dist/fe)*CO2_hybrid*1000;
                    case 'EV',     CO2 = 0;
                end
                if ~strcmp(fuel,'EV')
                    CH4 = dist*CH4_f; N2O = dist*N2O_f;
                end

            case 'Bus'
                fuel = fuelDD.Value;
                if strcmp(fuel,'Diesel')
                    CO2 = dist*105; CH4 = dist*CH4_f; N2O = dist*N2O_f;
                end

            case 'Train'
                fuel = fuelDD.Value;
                if strcmp(fuel,'Diesel')
                    fu  = (dist/100)*avg_eff(1);
                    CO2 = fu*CO2_diesel*1000; CH4 = dist*CH4_f; N2O = dist*N2O_f;
                end

            case 'Airplane'
                fu = (dist/100)*avg_eff(2);
                CO2 = fu*3.16*1000; CH4 = dist*CH4_f; N2O = dist*N2O_f;

            case 'Underground'
                % all zero
        end
        direct_g  = CO2 + CH4*GWP_CH4 + N2O*GWP_N2O;
        direct_kg = direct_g/1000;
        CO2_kg    = CO2/1000;
        CH4_kg    = CH4/1000;
        N2O_kg    = N2O/1000;

        %% Indirect
        switch mode
            case 'Car'
                elec = strcmp(fuel,'EV') * ((feField.Value/100)*CI*dist);
            case 'Bus'
                elec = strcmp(fuel,'Electric') * (0.025*CI*dist);
            case 'Train'
                elec = strcmp(fuel,'Electric') * (0.069*CI*dist);
            case 'Underground'
                elec = 0.116*CI*dist;
            otherwise
                elec = 0;
        end

        % Fuel production
        switch mode
            case 'Car'
                if ismember(fuel,{'Petrol','PHEV'}), fp = 24*dist;
                elseif strcmp(fuel,'Diesel'),       fp = 22*dist;
                else                               , fp = 0;
                end
            case 'Bus'
                switch fuel
                    case 'Diesel',     fp = 22*dist;
                    case 'Biomethane', fp = 0.14*dist;
                    otherwise,        fp = 0;
                end
            case 'Train'
                fp = strcmp(fuel,'Diesel') * 22 * dist;
            case 'Airplane'
                fp = 10 * dist;
            otherwise
                fp = 0;
        end

        % Manufacturing
        switch mode
            case 'Car'
                switch fuel
                    case 'EV',      manuf = 48*dist;
                    case 'PHEV',    manuf = 37*dist;
                    case 'Diesel',  manuf = 31*dist;
                    otherwise,     manuf = 30*dist;
                end
            case 'Bus',       manuf = bus_man*dist;
            case {'Train','Underground'}, manuf = train_man*dist;
            case 'Airplane',  manuf = 0.13*dist;
            otherwise,        manuf = 0;
        end

        % End-of-life
        switch mode
            case 'Car'
                switch fuel
                    case {'EV','PHEV'}, eol = 9*dist;
                    otherwise,         eol = 6*dist;
                end
            case 'Bus',       eol = bus_eol*dist;
            case {'Train','Underground'}, eol = train_eol*dist;
            case 'Airplane',  eol = 0.013*dist;
            otherwise,        eol = 0;
        end

        indirect_g  = elec + fp + manuf + eol;
        indirect_kg = indirect_g/1000;
        elec_kg     = elec/1000;
        fp_kg       = fp/1000;
        manuf_kg    = manuf/1000;
        eol_kg      = eol/1000;

        %% Display results
        lines = {
            '--- Direct Emissions ---'
            sprintf('CO₂:        %.2f g (%.3f kg)', CO2,    CO2_kg)
            sprintf('N₂O:        %.2f g (%.3f kg)', N2O,    N2O_kg)
            sprintf('CH₄:        %.2f g (%.3f kg)', CH4,    CH4_kg)
            sprintf('Total CO₂e: %.2f g (%.3f kg)', direct_g, direct_kg)
            ''
            '--- Indirect Emissions ---'
        };

        if elec>0
            lines{end+1} = sprintf('Electricity Gen:    %.2f g (%.3f kg)', elec, elec_kg);
        else
            lines{end+1} = sprintf('Fuel Production:    %.2f g (%.3f kg)', fp,    fp_kg);
        end
        lines{end+1} = sprintf('Manufacturing:           %.2f g (%.3f kg)', manuf,   manuf_kg);
        lines{end+1} = sprintf('End-of-Life:             %.2f g (%.3f kg)', eol,      eol_kg);
        lines{end+1} = sprintf('Total Indirect CO₂e: %.2f g (%.3f kg)', indirect_g, indirect_kg);

        if ismember(mode,{'Bus','Train','Airplane','Underground'})
            lines{end+1} = '';
            lines{end+1} = 'Note: per-passenger values.';
        end
        lines{end+1} = '';
        lifecycle_g = direct_g + indirect_g;
        lifecycle_kg = lifecycle_g/1000;
        lines{end+1} = sprintf('Lifecycle Total CO₂e: %.2f g (%.3f kg)', lifecycle_g, lifecycle_kg);

        resultsArea.Value = lines;

        %% Chart
        if elec>0
            secondVal   = elec;
            secondLabel = 'Electricity Gen';
        else
            secondVal   = fp;
            secondLabel = 'Fuel Production';
        end
        vals   = [direct_g, secondVal, manuf, eol];
        labels = {'Direct CO₂e', secondLabel, 'Manufacturing','End-of-Life'};
        bar(axesContainer, vals,'FaceColor','flat');
        axesContainer.XTickLabel = labels;
        ylabel(axesContainer,'g CO₂e');
        title(axesContainer,'Emissions Breakdown');
    end

end

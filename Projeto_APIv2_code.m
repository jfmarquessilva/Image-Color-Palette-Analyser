%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NAME: 
%     Projeto_APIv2_code
% 
% AUTHOR:
%     João Fernando Marques da Silva 2015238186
%     
% PURPOSE:
%     Generate the color palette of a RGB image and 
%     classify the various colours in the image by 
%     their HTML code. The generated color palette
%     can be saved to a file ('*.jpg', '*.png' or '*.tif').
% 
% CALLING SEQUENCE:
%     To run this program run the Matlab Application 
%     provided 'Projeto_APIv2.mlapp'.
% 
% INPUTS:
%     RGB image ('*.jpg', '*.png' or '*.tif').
%     Number of colours on the generated palette.
% 
% OUTPUTS:
%     Returns a colour palette of the provided image
%     with the specified number of colours.
%     
% SIDE EFFECTS:
%     For higher numbers of colours in the palette (>15)
%     the resolution of the displayed palette in the Matlab
%     interface doesn't allow to properly read the color 
%     codes. However, the saved files all have the same 
%     quality, independent of their number of colours.
%
% RESTRICTIONS:
%     None.
% 
% PROCEDURE:
%     The inputed image is converted to the L*a*b colour space
%     (see REFERENCES), then the image is separated in a user
%     defined number of clusters using the kmeans method. The
%     clusters are used to segment the original image accordingly
%     to the colours detected. The pixel values are then averaged
%     to determine the colour of each segment.
% 
% REFERENCES:
%     The L*a*b colour space and the kmeans method were chosen 
%     as the best for this application based on this link:
%     https://mollermara.com/blog/kmeans/
% 
% WARNING:
%     The following error may arise:
%     'Undefined function 'insertText' for input arguments of type 'cell''
%     (I have verified with some of my coleagues and that happens
%     because a toolbox is missing).
%     If the error happens please contact me at:
%     jsilva199718@hotmail.com
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    

classdef Projeto_APIv2_code < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        Image                           matlab.ui.control.UIAxes
        SelectImageButton               matlab.ui.control.Button
        NumberofColoursinPaletteSliderLabel  matlab.ui.control.Label
        NumberofColoursinPaletteSlider  matlab.ui.control.Slider
        GeneratePaletteButton           matlab.ui.control.Button
        ExportPaletteButton             matlab.ui.control.Button
    end


    properties (Access = private)
        ImageSelected;
        Palette;
        NumberColours = 1;
    end


    methods (Access = private)

        % Button pushed function: SelectImageButton
        function SelectImageButtonPushed(app, event)
            [filename,path] = uigetfile({'*.jpg'; '*.png'; '*.tif'});   %reads image from directory
            cd (path);
            im = strsplit(filename, '.');
            image = imread(filename, im{end});
            imshow(image,'Parent',app.Image,'InitialMagnification','fit');
            app.ImageSelected = image;                                  %assigns a value to the app property ImageSelected
        end

        % Value changed function: NumberofColoursinPaletteSlider
        function NumberofColoursinPaletteSliderValueChanged(app, event)
            value = app.NumberofColoursinPaletteSlider.Value;      %reads slider value 
            N_palette = round(value);                              %rounds the slider value to an integer
            app.NumberofColoursinPaletteSlider.Value = N_palette;  %displays the rounded value in the GUI
            app.NumberColours = N_palette;                         %assigns a value to the app property NumberColours
        end

        % Button pushed function: GeneratePaletteButton
        function GeneratePaletteButtonPushed(app, event)
            image = app.ImageSelected;
            N_palette = app.NumberColours; %defines the number of clusters
            
            im_converted = rgb2lab(image); %converts from RGB to the L*a*b colour space
            [m,n,d] = size(image);
            N = m*n;
            X = reshape(im_converted,N,d); %reshapes to a 2D matrix
            
            idx = kmeans(X, N_palette); %uses the k-means method to find different clusters of colours
            idx_reshape = reshape(idx, m, n, 1); %reshapes to a 2D matrix with the same m-n of the original image
            
            image_seg = image;
            colours = uint8(zeros(300,80*N_palette,3));
            colour_code = {};
            colour_ind = 0;
            
            for i = 1:N_palette
    
                code = '#';
                %segmets the original image
                mask = (idx_reshape == i);
                image_seg(:,:,1) = double(image(:,:,1)).*mask;
                image_seg(:,:,2) = double(image(:,:,2)).*mask;
                image_seg(:,:,3) = double(image(:,:,3)).*mask;
    
                %calculates the average value of colour in each segmented image
                for j = 1:3
                    tot = 0;
                    n_vals = 0;
                    for k = 1:m
                        for l = 1:n
                            if image_seg(k,l,j) ~= 0
                                tot = tot + double(image_seg(k,l,j));
                                n_vals = n_vals + 1;
                            end
                        end
                    end
                    col_med = tot/n_vals;
                    colours(:,1+80*colour_ind:80+80*colour_ind,j) = uint8(col_med);
                    code = strcat(code,dec2hex(uint8(col_med),2)); %converts the obtained colour values to their html code
                end
    
                colour_code{i} = code;
                colour_ind = colour_ind +1;
    
            end
            
            text_positions = [18 260];
            
            for ind = 1:N_palette-1
                 text_positions = [text_positions; [18+80*ind 260]];
            end
            
            colours = insertText(colours,text_positions,colour_code,'FontSize',10,'BoxColor','white','TextColor','black');
            app.Palette = colours;
            
            figure ('name','Colour Palette','NumberTitle','off')
            imshow(colours);
        end

        % Button pushed function: ExportPaletteButton
        function ExportPaletteButtonPushed(app, event)
            colours = app.Palette;
            [SaveFile, path] = uiputfile({'*.jpg';'*.png';'*.tif'}); %chooses which file to save to
            cd (path)
            im = strsplit(SaveFile, '.');
            imwrite(colours,SaveFile,im{end}); %saves the colour palette to a file
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure
            app.UIFigure = uifigure;
            app.UIFigure.Position = [100 100 472 480];
            app.UIFigure.Name = 'UI Figure';
            setAutoResize(app, app.UIFigure, true)

            % Create Image
            app.Image = uiaxes(app.UIFigure);
            title(app.Image, 'Image');
            app.Image.Box = 'on';
            app.Image.XTick = [];
            app.Image.XTickMode = 'manual';
            app.Image.YTick = [];
            app.Image.YTickMode = 'manual';
            app.Image.Position = [28 160 418 310];

            % Create SelectImageButton
            app.SelectImageButton = uibutton(app.UIFigure, 'push');
            app.SelectImageButton.ButtonPushedFcn = createCallbackFcn(app, @SelectImageButtonPushed, true);
            app.SelectImageButton.Position = [187 126 100 22];
            app.SelectImageButton.Text = 'Select Image';

            % Create NumberofColoursinPaletteSliderLabel
            app.NumberofColoursinPaletteSliderLabel = uilabel(app.UIFigure);
            app.NumberofColoursinPaletteSliderLabel.HorizontalAlignment = 'center';
            app.NumberofColoursinPaletteSliderLabel.VerticalAlignment = 'center';
            app.NumberofColoursinPaletteSliderLabel.Position = [49 91 162 15];
            app.NumberofColoursinPaletteSliderLabel.Text = 'Number of Colours in Palette';

            % Create NumberofColoursinPaletteSlider
            app.NumberofColoursinPaletteSlider = uislider(app.UIFigure);
            app.NumberofColoursinPaletteSlider.Limits = [1 20];
            app.NumberofColoursinPaletteSlider.MajorTicks = [1 5 10 15 20];
            app.NumberofColoursinPaletteSlider.MajorTickLabels = {'1', '5', '10', '15', '20'};
            app.NumberofColoursinPaletteSlider.ValueChangedFcn = createCallbackFcn(app, @NumberofColoursinPaletteSliderValueChanged, true);
            app.NumberofColoursinPaletteSlider.MinorTicks = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20];
            app.NumberofColoursinPaletteSlider.Position = [34 75 190 3];
            app.NumberofColoursinPaletteSlider.Value = 1;

            % Create GeneratePaletteButton
            app.GeneratePaletteButton = uibutton(app.UIFigure, 'push');
            app.GeneratePaletteButton.ButtonPushedFcn = createCallbackFcn(app, @GeneratePaletteButtonPushed, true);
            app.GeneratePaletteButton.Position = [311.5 84 117 22];
            app.GeneratePaletteButton.Text = 'Generate Palette';

            % Create ExportPaletteButton
            app.ExportPaletteButton = uibutton(app.UIFigure, 'push');
            app.ExportPaletteButton.ButtonPushedFcn = createCallbackFcn(app, @ExportPaletteButtonPushed, true);
            app.ExportPaletteButton.Position = [312 42 117 22];
            app.ExportPaletteButton.Text = 'Export Palette';
        end
    end

    methods (Access = public)

        % Construct app
        function app = Projeto_APIv2()

            % Create and configure components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
document.addEventListener('DOMContentLoaded', () => {
    // DOM Elements
    const spritesheetContainer = document.getElementById('spritesheet-container');
    const spritesheetImage = document.getElementById('spritesheet-image');
    const loadedSpritesheetSource = document.getElementById('loaded-spritesheet-source');
    const overlayCanvas = document.getElementById('overlay-canvas');
    const overlayCtx = overlayCanvas.getContext('2d');
    const animationStatesListEl = document.getElementById('animation-states-list');
    const previewCanvas = document.getElementById('preview-canvas');
    const previewCtx = previewCanvas.getContext('2d');
    const loadingMessage = document.getElementById('loading-message');
    const errorMessageElement = document.getElementById('error-message');
    const editorContent = document.getElementById('editor-content');
    const currentAnimationInfo = document.getElementById('current-animation-info');
    
    const saveAnimationButton = document.getElementById('save-animation-button');
    const saveStatusMessage = document.getElementById('save-status-message');
    const imagePathInput = document.getElementById('image-path-input');
    const addAnimationStateButton = document.getElementById('add-animation-state-button');
    const frameEditorPanel = document.getElementById('frame-editor-panel');
    const frameEditorPlaceholder = document.getElementById('frame-editor-placeholder');
    const addFrameButton = document.getElementById('add-frame-button');
    const currentFramesListEl = document.getElementById('current-frames-list');

    const zoomInButton = document.getElementById('zoom-in-button');
    const zoomOutButton = document.getElementById('zoom-out-button');
    const zoomLevelDisplay = document.getElementById('zoom-level-display');

    // --- NEW DOM Element for the "Apply Offset All" button ---
    // Make sure you have a button with id="apply-offset-all-button" in your HTML
    const applyOffsetAllButton = document.getElementById('apply-offset-all-button'); 

    // --- Application State ---
    let animationData = { imagePath: "", animations: {} };
    let currentSelectedStateName = null;
    let currentSelectedFrameIndex = -1;
    
    let currentPlayingAnimationName = null;
    let currentPlayingFrameIndex = 0;
    let elapsedTimeSinceLastFrame = 0;
    let lastTimestamp = 0;
    let animationRequestID;
    let activeStateListItem = null;
    let activeFrameListItem = null;

    let currentZoomLevel = 1.0;
    const MIN_ZOOM = 0.25;
    const MAX_ZOOM = 8.0;
    const ZOOM_STEP = 0.25;

    let isDraggingFrame = false;
    let isResizingFrame = false;
    let dragStartX, dragStartY; 
    let frameInitialX, frameInitialY, frameInitialW, frameInitialH; 
    let currentResizeHandle = null; 
    const HANDLE_SIZE = 8; 
    let mouseOverHandle = null; 

    // Preview background tile
    const previewTileImage = new Image();
    let previewTileLoaded = false;
    let previewTileOffsetX = 0; 
    let previewTileOffsetY = 0; 


    // --- Initialization ---
    async function initializeEditor() {
        // Load preview tile
        previewTileImage.onload = () => {
            previewTileLoaded = true;
            if (currentPlayingAnimationName) playAnimationForPreview(currentPlayingAnimationName);
            console.log("Preview tile loaded.");
        };
        previewTileImage.onerror = () => {
            console.error("Failed to load preview tile image from: " + PREVIEW_TILE_URL);
        };
        previewTileImage.src = PREVIEW_TILE_URL; 

        try {
            const response = await fetch(API_ENDPOINT_LOAD);
            if (!response.ok) {
                const errorData = await response.json().catch(() => ({ detail: "Unknown server error" }));
                throw new Error(`Failed to load animation data: ${response.status} ${response.statusText}. ${errorData.detail || errorData.error || ""}`);
            }
            const loadedData = await response.json();
            animationData = {
                imagePath: loadedData.imagePath || "",
                animations: loadedData.animations || {},
                errors: loadedData.errors || []
            };

            if (animationData.errors && animationData.errors.length > 0) {
                console.warn("Parsing errors from file:", animationData.errors);
                showError("Warning: Issues found while parsing the animation file. Check console. Errors: " + animationData.errors.join("; "), true);
            }
            
            if (!animationData.imagePath && Object.keys(animationData.animations).length === 0 && (!animationData.errors || animationData.errors.length === 0) ) {
                 console.log("Loaded empty or new animation file.");
            } else if (!animationData.imagePath && Object.keys(animationData.animations).length > 0) {
                showError("Warning: Animation data present but imagePath is missing. Spritesheet cannot be loaded.", true);
            }

            loadingMessage.classList.add('hidden');
            editorContent.classList.remove('hidden');
            
            imagePathInput.value = animationData.imagePath || "";
            loadAndDisplaySpritesheet(); 
            populateAnimationStatesList();
            renderFrameEditor(); 
            renderFramesListForState();
            setupOverlayCanvasListeners(); 
            setupZoomListeners();
            updateZoomDisplay();

            // --- Add Event Listener for the new button ---
            if(applyOffsetAllButton) { // Check if the button exists in HTML
                applyOffsetAllButton.addEventListener('click', applyOffsetToAllFrames);
            } else {
                console.warn("Button with ID 'apply-offset-all-button' not found in the DOM.");
            }

        } catch (error) {
            console.error("Initialization error:", error);
            showError(`Critical Error: ${error.message}. Check console and file format.`);
            loadingMessage.classList.add('hidden');
        }
    }

    function loadAndDisplaySpritesheet() {
        if (animationData.imagePath) {
            loadedSpritesheetSource.onload = () => {
                spritesheetImage.src = loadedSpritesheetSource.src;
                applyZoom(); 
            };
            loadedSpritesheetSource.onerror = () => {
                showError(`Failed to load spritesheet: ${getAssetUrl(animationData.imagePath)}. Check path.`, true);
                spritesheetImage.src = "https://placehold.co/300x200/2D3748/E2E8F0?text=Error+Loading+Image";
                overlayCanvas.width = 300; 
                overlayCanvas.height = 200;
                spritesheetImage.style.width = '300px';
                spritesheetImage.style.height = '200px';
                overlayCtx.clearRect(0,0,300,200);
            };
            loadedSpritesheetSource.src = getAssetUrl(animationData.imagePath);
        } else {
            spritesheetImage.src = "https://placehold.co/300x200/2D3748/E2E8F0?text=No+Image+Path";
            overlayCanvas.width = 300; 
            overlayCanvas.height = 200;
            spritesheetImage.style.width = '300px';
            spritesheetImage.style.height = '200px';
            overlayCtx.clearRect(0,0,300,200);
            console.log("No image path set.");
            applyZoom(); 
        }
    }

    function showError(message, isWarning = false) {
        errorMessageElement.textContent = message;
        errorMessageElement.classList.remove('hidden');
        errorMessageElement.classList.toggle('bg-red-900', !isWarning);
        errorMessageElement.classList.toggle('border-red-700', !isWarning);
        errorMessageElement.classList.toggle('text-red-400', !isWarning);
        errorMessageElement.classList.toggle('bg-yellow-900', isWarning);
        errorMessageElement.classList.toggle('border-yellow-700', isWarning);
        errorMessageElement.classList.toggle('text-yellow-400', isWarning);
        if (!isWarning) editorContent.classList.add('hidden');
    }

    function setupZoomListeners() {
        zoomInButton.addEventListener('click', () => changeZoom(ZOOM_STEP));
        zoomOutButton.addEventListener('click', () => changeZoom(-ZOOM_STEP));
    }

    function changeZoom(delta) {
        const newZoom = Math.max(MIN_ZOOM, Math.min(MAX_ZOOM, currentZoomLevel + delta));
        if (newZoom !== currentZoomLevel) {
            currentZoomLevel = parseFloat(newZoom.toFixed(2)); 
            applyZoom();
            updateZoomDisplay();
        }
    }

    function applyZoom() {
        if (!loadedSpritesheetSource.complete || loadedSpritesheetSource.naturalWidth === 0) {
            const baseWidth = spritesheetImage.src.startsWith("https://placehold.co") ? 300 : (loadedSpritesheetSource.naturalWidth || 100);
            const baseHeight = spritesheetImage.src.startsWith("https://placehold.co") ? 200 : (loadedSpritesheetSource.naturalHeight || 100);
            
            spritesheetImage.style.width = `${baseWidth * currentZoomLevel}px`;
            spritesheetImage.style.height = `${baseHeight * currentZoomLevel}px`;
            overlayCanvas.width = baseWidth * currentZoomLevel;
            overlayCanvas.height = baseHeight * currentZoomLevel;
        } else {
            spritesheetImage.style.width = `${loadedSpritesheetSource.naturalWidth * currentZoomLevel}px`;
            spritesheetImage.style.height = `${loadedSpritesheetSource.naturalHeight * currentZoomLevel}px`;
            overlayCanvas.width = loadedSpritesheetSource.naturalWidth * currentZoomLevel;
            overlayCanvas.height = loadedSpritesheetSource.naturalHeight * currentZoomLevel;
        }
        drawAllFrameOutlines();
    }

    function updateZoomDisplay() {
        zoomLevelDisplay.textContent = `${Math.round(currentZoomLevel * 100)}%`;
    }


    function drawAllFrameOutlines() {
        overlayCtx.clearRect(0, 0, overlayCanvas.width, overlayCanvas.height);
        if (!animationData || !animationData.animations) return;

        overlayCtx.save();
        overlayCtx.scale(currentZoomLevel, currentZoomLevel); 

        const stateNames = Object.keys(animationData.animations);
        stateNames.forEach(stateName => {
            if (stateName === currentSelectedStateName) return; 
            const frames = animationData.animations[stateName];
            frames.forEach(frame => drawSingleFrameOutline(frame, 'rgba(150, 0, 0, 0.4)', 1, [4,2]));
        });
        
        if (currentSelectedStateName && animationData.animations[currentSelectedStateName]) {
            animationData.animations[currentSelectedStateName].forEach((frame, index) => {
                if (index !== currentSelectedFrameIndex) {
                    drawSingleFrameOutline(frame, 'rgba(255, 0, 0, 0.5)', 1, [4,2]);
                }
            });
        }

        if (currentSelectedStateName && animationData.animations[currentSelectedStateName] && currentSelectedFrameIndex !== -1) {
            const selectedFrame = animationData.animations[currentSelectedStateName][currentSelectedFrameIndex];
            if (selectedFrame) {
                drawSingleFrameOutline(selectedFrame, 'rgba(50, 205, 50, 0.9)', 2 / currentZoomLevel); 
                drawResizeHandles(selectedFrame);
            }
        }
        overlayCtx.restore(); 
    }

    function drawSingleFrameOutline(frame, strokeStyle, lineWidth, lineDash = []) {
        try {
            const x = parseFloat(frame.x);
            const y = parseFloat(frame.y);
            const w = parseFloat(frame.w);
            const h = parseFloat(frame.h);
            if (isNaN(x) || isNaN(y) || isNaN(w) || isNaN(h) || w <= 0 || h <= 0) return;

            overlayCtx.strokeStyle = strokeStyle;
            overlayCtx.lineWidth = lineWidth; 
            overlayCtx.setLineDash(lineDash.map(d => d / currentZoomLevel)); 
            overlayCtx.strokeRect(x, y, w, h);
            overlayCtx.setLineDash([]);
        } catch (e) { console.error("Error drawing frame outline:", e); }
    }
    
    function drawResizeHandles(frame) {
        const x = parseFloat(frame.x);
        const y = parseFloat(frame.y);
        const w = parseFloat(frame.w);
        const h = parseFloat(frame.h);
        if (isNaN(x) || isNaN(y) || isNaN(w) || isNaN(h)) return;

        overlayCtx.fillStyle = 'rgba(50, 205, 50, 0.8)';
        overlayCtx.strokeStyle = 'rgba(255, 255, 255, 0.9)';
        
        const effectiveHandleSize = HANDLE_SIZE / currentZoomLevel; 
        overlayCtx.lineWidth = 1 / currentZoomLevel; 

        const handles = getHandlePositions(x, y, w, h); 
        for (const handleKey in handles) {
            const pos = handles[handleKey]; 
            overlayCtx.fillRect(
                pos.x - effectiveHandleSize / 2, 
                pos.y - effectiveHandleSize / 2, 
                effectiveHandleSize, 
                effectiveHandleSize
            );
            overlayCtx.strokeRect(
                pos.x - effectiveHandleSize / 2, 
                pos.y - effectiveHandleSize / 2, 
                effectiveHandleSize, 
                effectiveHandleSize
            );
        }
    }

    function getHandlePositions(x, y, w, h) { 
        return {
            topLeft: { x: x, y: y }, topRight: { x: x + w, y: y },
            bottomLeft: { x: x, y: y + h }, bottomRight: { x: x + w, y: y + h },
            top: { x: x + w / 2, y: y }, bottom: { x: x + w / 2, y: y + h },
            left: { x: x, y: y + h / 2 }, right: { x: x + w, y: y + h / 2 },
        };
    }

    function getHandleAtPoint(mouseX, mouseY, frame) { 
        const x = parseFloat(frame.x);
        const y = parseFloat(frame.y);
        const w = parseFloat(frame.w);
        const h = parseFloat(frame.h);
        if (isNaN(x) || isNaN(y) || isNaN(w) || isNaN(h)) return null;

        const handles = getHandlePositions(x, y, w, h);
        const halfHandleInImagePixels = (HANDLE_SIZE / currentZoomLevel) / 2;

        for (const handleKey in handles) {
            const pos = handles[handleKey]; 
            if (mouseX >= pos.x - halfHandleInImagePixels && mouseX <= pos.x + halfHandleInImagePixels &&
                mouseY >= pos.y - halfHandleInImagePixels && mouseY <= pos.y + halfHandleInImagePixels) {
                return handleKey;
            }
        }
        return null;
    }
    
    function isPointInRect(px, py, rx, ry, rw, rh) { 
        return px >= rx && px <= rx + rw && py >= ry && py <= ry + rh;
    }

    function getMousePos(canvas, evt) { 
        const rect = canvas.getBoundingClientRect(); 
        return {
            x: (evt.clientX - rect.left + spritesheetContainer.scrollLeft) / currentZoomLevel,
            y: (evt.clientY - rect.top + spritesheetContainer.scrollTop) / currentZoomLevel
        };
    }

    function populateAnimationStatesList() {
        animationStatesListEl.innerHTML = '';
        if (!animationData || !animationData.animations || Object.keys(animationData.animations).length === 0) {
            animationStatesListEl.innerHTML = '<li class="text-gray-400 italic p-2">No animation states defined.</li>';
            return;
        }

        const stateNames = Object.keys(animationData.animations).sort();
        stateNames.forEach(stateName => {
            const li = document.createElement('li');
            li.className = "flex justify-between items-center p-1 group";

            const nameButton = document.createElement('button');
            nameButton.textContent = stateName;
            nameButton.className = "flex-grow text-left px-2 py-1 rounded-md text-sky-200 hover:bg-sky-600 hover:text-white transition-colors duration-150 focus:outline-none focus:ring-1 focus:ring-sky-400";
            if (stateName === currentSelectedStateName) {
                nameButton.classList.add('bg-sky-500', 'text-white');
                activeStateListItem = nameButton;
            }
            nameButton.onclick = () => {
                currentSelectedStateName = stateName;
                currentSelectedFrameIndex = -1; 
                if (activeStateListItem) activeStateListItem.classList.remove('bg-sky-500', 'text-white');
                nameButton.classList.add('bg-sky-500', 'text-white');
                activeStateListItem = nameButton;
                
                playAnimationForPreview(stateName); 
                renderFramesListForState();
                renderFrameEditor(); 
                drawAllFrameOutlines(); 
            };

            const controlsDiv = document.createElement('div');
            controlsDiv.className = "opacity-0 group-hover:opacity-100 transition-opacity flex items-center space-x-1 ml-2";
            const renameButton = document.createElement('button');
            renameButton.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path></svg>`;
            renameButton.title = "Rename State";
            renameButton.className = "p-1 rounded hover:bg-gray-500 text-yellow-400 hover:text-yellow-300";
            renameButton.onclick = (e) => { e.stopPropagation(); renameAnimationState(stateName); };
            const deleteButton = document.createElement('button');
            deleteButton.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path><line x1="10" y1="11" x2="10" y2="17"></line><line x1="14" y1="11" x2="14" y2="17"></line></svg>`;
            deleteButton.title = "Delete State";
            deleteButton.className = "p-1 rounded hover:bg-gray-500 text-red-400 hover:text-red-300";
            deleteButton.onclick = (e) => { e.stopPropagation(); deleteAnimationState(stateName); };
            controlsDiv.appendChild(renameButton);
            controlsDiv.appendChild(deleteButton);
            li.appendChild(nameButton);
            li.appendChild(controlsDiv);
            animationStatesListEl.appendChild(li);
        });
    }
    
    function renderFramesListForState() {
        currentFramesListEl.innerHTML = "";
        addFrameButton.classList.toggle('hidden', !currentSelectedStateName);

        if (!currentSelectedStateName || !animationData.animations[currentSelectedStateName]) {
            currentFramesListEl.innerHTML = '<li class="text-gray-400 italic p-2">No state selected or state has no frames.</li>';
            return;
        }

        const frames = animationData.animations[currentSelectedStateName];
        if (frames.length === 0) {
            currentFramesListEl.innerHTML = '<li class="text-gray-400 italic p-2">This state has no frames. Click "+ Add Frame".</li>';
            return;
        }

        frames.forEach((frame, index) => {
            const li = document.createElement('li');
            const frameButton = document.createElement('button');
            frameButton.textContent = `Frame ${index + 1} (Dur: ${frame.duration || 'N/A'})`;
            frameButton.className = "w-full text-left px-2 py-1 rounded-md text-gray-300 hover:bg-sky-700 focus:outline-none focus:ring-1 focus:ring-sky-500";
            if (index === currentSelectedFrameIndex) {
                frameButton.classList.add('bg-sky-600', 'text-white');
                activeFrameListItem = frameButton;
            }

            frameButton.onclick = () => {
                currentSelectedFrameIndex = index;
                if(activeFrameListItem) activeFrameListItem.classList.remove('bg-sky-600', 'text-white');
                frameButton.classList.add('bg-sky-600', 'text-white');
                activeFrameListItem = frameButton;
                renderFrameEditor();
                drawAllFrameOutlines(); 
            };
            li.appendChild(frameButton);
            currentFramesListEl.appendChild(li);
        });
    }

    function renderFrameEditor() {
        frameEditorPanel.innerHTML = ''; 
        if (!currentSelectedStateName || currentSelectedFrameIndex === -1 || 
            !animationData.animations[currentSelectedStateName] || 
            !animationData.animations[currentSelectedStateName][currentSelectedFrameIndex]) {
            frameEditorPanel.appendChild(frameEditorPlaceholder);
            frameEditorPlaceholder.classList.remove('hidden');
            return;
        }
        frameEditorPlaceholder.classList.add('hidden');

        const frame = animationData.animations[currentSelectedStateName][currentSelectedFrameIndex];
        if (!frame) { 
            frameEditorPanel.appendChild(frameEditorPlaceholder); return;
        }

        const fields = [
            { label: 'Duration', key: 'duration', type: 'number', step: '0.01' }, { label: 'X', key: 'x', type: 'number' },
            { label: 'Y', key: 'y', type: 'number' }, { label: 'Width (W)', key: 'w', type: 'number' },
            { label: 'Height (H)', key: 'h', type: 'number' }, { label: 'Origin X', key: 'originx', type: 'number' },
            { label: 'Origin Y', key: 'originy', type: 'number' }, { label: 'Flip X', key: 'flipx', type: 'checkbox' }
        ];

        fields.forEach(field => {
            const div = document.createElement('div');
            const labelEl = document.createElement('label');
            labelEl.htmlFor = `frame-prop-${field.key}`;
            labelEl.textContent = `${field.label}:`;
            labelEl.className = "block text-sm font-medium text-gray-300 mb-1";
            const inputEl = document.createElement('input');
            inputEl.id = `frame-prop-${field.key}`;
            
            if (field.type === 'checkbox') {
                div.className = "flex items-center mb-2";
                inputEl.type = 'checkbox';
                inputEl.className = "form-checkbox h-5 w-5 text-sky-500 bg-gray-700 border-gray-600 rounded focus:ring-sky-400 mr-2";
                const currentFlipX = frame[field.key];
                inputEl.checked = currentFlipX === '1' || currentFlipX === 1 || currentFlipX === true;
                inputEl.onchange = (e) => { 
                    frame[field.key] = e.target.checked ? '1' : '0';
                    if (currentPlayingAnimationName === currentSelectedStateName) playAnimationForPreview(currentSelectedStateName); 
                };
                div.appendChild(inputEl); 
                div.appendChild(labelEl); 
            } else {
                div.className = "mb-2";
                inputEl.type = field.type;
                inputEl.className = 'input-field input-field-sm';
                inputEl.value = frame[field.key] || (field.type === 'number' ? '0' : '');
                if (field.step) inputEl.step = field.step;
                inputEl.onchange = (e) => { 
                    frame[field.key] = e.target.value;
                    drawAllFrameOutlines(); 
                    if (currentPlayingAnimationName === currentSelectedStateName) playAnimationForPreview(currentSelectedStateName);
                };
                div.appendChild(labelEl);
                div.appendChild(inputEl);
            }
            frameEditorPanel.appendChild(div);
        });
        
        const removeFrameBtn = document.createElement('button');
        removeFrameBtn.textContent = 'Delete This Frame';
        removeFrameBtn.className = 'btn btn-danger btn-sm mt-3 w-full';
        removeFrameBtn.onclick = () => deleteFrame(currentSelectedStateName, currentSelectedFrameIndex);
        frameEditorPanel.appendChild(removeFrameBtn);
    }

    function setupOverlayCanvasListeners() {
        overlayCanvas.addEventListener('mousedown', handleMouseDown);
        overlayCanvas.addEventListener('mousemove', handleMouseMove);
        overlayCanvas.addEventListener('mouseup', handleMouseUp);
        overlayCanvas.addEventListener('mouseleave', handleMouseLeave); 
    }

    function handleMouseDown(e) {
        e.preventDefault();
        const mousePos = getMousePos(overlayCanvas, e); 

        if (!currentSelectedStateName || !animationData.animations[currentSelectedStateName]) return;
        const framesInCurrentState = animationData.animations[currentSelectedStateName];

        if (currentSelectedFrameIndex !== -1) {
            const selectedFrame = framesInCurrentState[currentSelectedFrameIndex];
            currentResizeHandle = getHandleAtPoint(mousePos.x, mousePos.y, selectedFrame);
            if (currentResizeHandle) {
                isResizingFrame = true;
                isDraggingFrame = false; 
                dragStartX = mousePos.x; 
                dragStartY = mousePos.y;
                frameInitialX = parseFloat(selectedFrame.x);
                frameInitialY = parseFloat(selectedFrame.y);
                frameInitialW = parseFloat(selectedFrame.w);
                frameInitialH = parseFloat(selectedFrame.h);
                overlayCanvas.style.cursor = getResizeCursor(currentResizeHandle);
                return;
            }
        }
        
        for (let i = framesInCurrentState.length - 1; i >= 0; i--) {
            const frame = framesInCurrentState[i];
            if (isPointInRect(mousePos.x, mousePos.y, parseFloat(frame.x), parseFloat(frame.y), parseFloat(frame.w), parseFloat(frame.h))) {
                if (currentSelectedFrameIndex !== i) { 
                    currentSelectedFrameIndex = i;
                    renderFramesListForState(); 
                    renderFrameEditor();       
                }
                isDraggingFrame = true;
                isResizingFrame = false; 
                dragStartX = mousePos.x; 
                dragStartY = mousePos.y;
                frameInitialX = parseFloat(frame.x);
                frameInitialY = parseFloat(frame.y);
                overlayCanvas.style.cursor = 'grabbing';
                drawAllFrameOutlines(); 
                return;
            }
        }

        if (currentSelectedFrameIndex !== -1) {
            currentSelectedFrameIndex = -1;
            renderFramesListForState();
            renderFrameEditor();
            drawAllFrameOutlines();
        }
        overlayCanvas.style.cursor = 'grab'; 
    }

    function handleMouseMove(e) {
        e.preventDefault();
        const mousePos = getMousePos(overlayCanvas, e); 
        let needsRedraw = false;

        if (isDraggingFrame && currentSelectedFrameIndex !== -1) {
            const frame = animationData.animations[currentSelectedStateName][currentSelectedFrameIndex];
            const dx = mousePos.x - dragStartX; 
            const dy = mousePos.y - dragStartY;
            frame.x = (frameInitialX + dx).toFixed(0); 
            frame.y = (frameInitialY + dy).toFixed(0);
            needsRedraw = true;
            overlayCanvas.style.cursor = 'grabbing';
        } else if (isResizingFrame && currentSelectedFrameIndex !== -1) {
            const frame = animationData.animations[currentSelectedStateName][currentSelectedFrameIndex];
            const dx = mousePos.x - dragStartX; 
            const dy = mousePos.y - dragStartY;
            let newX = frameInitialX, newY = frameInitialY, newW = frameInitialW, newH = frameInitialH;

            switch (currentResizeHandle) {
                case 'topLeft': newX = frameInitialX + dx; newY = frameInitialY + dy; newW = frameInitialW - dx; newH = frameInitialH - dy; break;
                case 'topRight': newY = frameInitialY + dy; newW = frameInitialW + dx; newH = frameInitialH - dy; break;
                case 'bottomLeft': newX = frameInitialX + dx; newW = frameInitialW - dx; newH = frameInitialH + dy; break;
                case 'bottomRight': newW = frameInitialW + dx; newH = frameInitialH + dy; break;
                case 'top': newY = frameInitialY + dy; newH = frameInitialH - dy; break;
                case 'bottom': newH = frameInitialH + dy; break;
                case 'left': newX = frameInitialX + dx; newW = frameInitialW - dx; break;
                case 'right': newW = frameInitialW + dx; break;
            }
            
            const minDim = HANDLE_SIZE / currentZoomLevel; 
            if (newW < minDim) { 
                if (currentResizeHandle.includes('Left')) newX = parseFloat(frame.x) + parseFloat(frame.w) - minDim; 
                newW = minDim; 
            }
            if (newH < minDim) { 
                if (currentResizeHandle.includes('Top')) newY = parseFloat(frame.y) + parseFloat(frame.h) - minDim; 
                newH = minDim; 
            }
            
            frame.x = newX.toFixed(0); frame.y = newY.toFixed(0);
            frame.w = newW.toFixed(0); 
            frame.h = newH.toFixed(0);
            needsRedraw = true;
            overlayCanvas.style.cursor = getResizeCursor(currentResizeHandle);
        } else { 
            updateCursorStyle(mousePos);
        }

        if (needsRedraw) {
            drawAllFrameOutlines();
            renderFrameEditor(); 
        }
    }
    
    function updateCursorStyle(mousePos) { 
        if (currentSelectedFrameIndex !== -1 && currentSelectedStateName && animationData.animations[currentSelectedStateName]) {
            const selectedFrame = animationData.animations[currentSelectedStateName][currentSelectedFrameIndex];
            if (selectedFrame) {
                mouseOverHandle = getHandleAtPoint(mousePos.x, mousePos.y, selectedFrame);
                if (mouseOverHandle) {
                    overlayCanvas.style.cursor = getResizeCursor(mouseOverHandle);
                    return;
                }
                if (isPointInRect(mousePos.x, mousePos.y, parseFloat(selectedFrame.x), parseFloat(selectedFrame.y), parseFloat(selectedFrame.w), parseFloat(selectedFrame.h))) {
                    overlayCanvas.style.cursor = 'move'; 
                    return;
                }
            }
        }
        overlayCanvas.style.cursor = 'grab'; 
    }

    function getResizeCursor(handle) {
        switch (handle) {
            case 'topLeft': case 'bottomRight': return 'nwse-resize';
            case 'topRight': case 'bottomLeft': return 'nesw-resize';
            case 'top': case 'bottom': return 'ns-resize';
            case 'left': case 'right': return 'ew-resize';
            default: return 'default';
        }
    }

    function handleMouseUp(e) {
        if (isDraggingFrame || isResizingFrame) {
            if (currentPlayingAnimationName === currentSelectedStateName) {
                 playAnimationForPreview(currentSelectedStateName); 
            }
            showSaveStatus("Frame updated. Remember to save.", "info", 2000);
        }
        isDraggingFrame = false;
        isResizingFrame = false;
        currentResizeHandle = null;
        const mousePos = getMousePos(overlayCanvas, e);
        updateCursorStyle(mousePos);
    }

    function handleMouseLeave(e) {
        if (isDraggingFrame || isResizingFrame) {
            handleMouseUp(e); 
        }
        overlayCanvas.style.cursor = 'grab'; 
    }

    function addNewAnimationState() {
        const newStateName = prompt("Enter name for new animation state:", `NewState_${Object.keys(animationData.animations).length + 1}`);
        if (newStateName && newStateName.trim() !== "") {
            if (animationData.animations[newStateName.trim()]) { alert("State name already exists."); return; }
            animationData.animations[newStateName.trim()] = [];
            currentSelectedStateName = newStateName.trim();
            currentSelectedFrameIndex = -1;
            populateAnimationStatesList(); renderFramesListForState(); renderFrameEditor(); drawAllFrameOutlines();
            showSaveStatus("New state added. Remember to save.", "info", 3000);
        }
    }

    function renameAnimationState(oldStateName) {
        const newStateName = prompt("Enter new name for state:", oldStateName);
        if (newStateName && newStateName.trim() !== "" && newStateName.trim() !== oldStateName) {
            if (animationData.animations[newStateName.trim()]) { alert("State name already exists."); return; }
            const frames = animationData.animations[oldStateName];
            delete animationData.animations[oldStateName];
            animationData.animations[newStateName.trim()] = frames;
            if (currentSelectedStateName === oldStateName) currentSelectedStateName = newStateName.trim();
            if (currentPlayingAnimationName === oldStateName) currentPlayingAnimationName = newStateName.trim();
            populateAnimationStatesList(); renderFramesListForState();
            showSaveStatus(`State '${oldStateName}' renamed. Remember to save.`, "info", 3000);
        }
    }

    function deleteAnimationState(stateName) {
        if (confirm(`Delete state "${stateName}"?`)) {
            delete animationData.animations[stateName];
            if (currentSelectedStateName === stateName) {
                currentSelectedStateName = null; currentSelectedFrameIndex = -1;
                if (animationRequestID) cancelAnimationFrame(animationRequestID);
                previewCtx.clearRect(0,0,previewCanvas.width, previewCanvas.height);
                currentAnimationInfo.textContent = "- Select an animation state -";
            }
            populateAnimationStatesList(); renderFramesListForState(); renderFrameEditor(); drawAllFrameOutlines();
            showSaveStatus(`State '${stateName}' deleted. Remember to save.`, "info", 3000);
        }
    }
    
    function addNewFrame() {
        if (!currentSelectedStateName || !animationData.animations[currentSelectedStateName]) { alert("Select state first."); return; }
        const newFrame = { duration: "0.1", x: "0", y: "0", w: "32", h: "32", originx: "16", originy: "16", flipx: "0" };
        const frames = animationData.animations[currentSelectedStateName];
        if (frames.length > 0) {
            const lastFrame = frames[frames.length -1];
            newFrame.x = (parseFloat(lastFrame.x) + parseFloat(lastFrame.w) + 5).toFixed(0);
            newFrame.y = lastFrame.y;
            const imageWidth = loadedSpritesheetSource.naturalWidth || overlayCanvas.width / currentZoomLevel;
            const imageHeight = loadedSpritesheetSource.naturalHeight || overlayCanvas.height / currentZoomLevel;

            if (parseFloat(newFrame.x) + parseFloat(newFrame.w) > imageWidth) { 
                newFrame.x = "0";
                newFrame.y = (parseFloat(lastFrame.y) + parseFloat(lastFrame.h) + 5).toFixed(0);
                if (parseFloat(newFrame.y) + parseFloat(newFrame.h) > imageHeight) {
                    newFrame.y = "0"; 
                }
            }
        }

        animationData.animations[currentSelectedStateName].push(newFrame);
        currentSelectedFrameIndex = animationData.animations[currentSelectedStateName].length - 1;
        renderFramesListForState(); renderFrameEditor(); drawAllFrameOutlines();
        showSaveStatus("New frame added. Remember to save.", "info", 3000);
    }

    function deleteFrame(stateName, frameIndex) {
        if (!animationData.animations[stateName] || !animationData.animations[stateName][frameIndex]) return;
        if (confirm(`Delete Frame ${frameIndex + 1} from "${stateName}"?`)) {
            animationData.animations[stateName].splice(frameIndex, 1);
            currentSelectedFrameIndex = -1; 
            renderFramesListForState(); renderFrameEditor(); drawAllFrameOutlines();
            showSaveStatus(`Frame deleted. Remember to save.`, "info", 3000);
        }
    }

    // --- NEW Function to apply offset to all frames ---
    function applyOffsetToAllFrames() {
        if (!animationData || !animationData.animations || Object.keys(animationData.animations).length === 0) {
            alert("No animation data or states available to apply offset.");
            return;
        }

        const offsetXStr = prompt("Enter X offset to apply to all frame origins (integer):", "0");
        if (offsetXStr === null) return; // User cancelled
        const offsetX = parseInt(offsetXStr, 10);
        if (isNaN(offsetX)) {
            alert("Invalid X offset. Please enter an integer.");
            return;
        }

        const offsetYStr = prompt("Enter Y offset to apply to all frame origins (integer):", "0");
        if (offsetYStr === null) return; // User cancelled
        const offsetY = parseInt(offsetYStr, 10);
        if (isNaN(offsetY)) {
            alert("Invalid Y offset. Please enter an integer.");
            return;
        }

        if (offsetX === 0 && offsetY === 0) {
            showSaveStatus("No offset applied (both X and Y are 0).", "info", 3000);
            return;
        }

        let framesModifiedCount = 0;
        Object.values(animationData.animations).forEach(stateFrames => {
            stateFrames.forEach(frame => {
                let currentOriginX = parseFloat(frame.originx);
                let currentOriginY = parseFloat(frame.originy);

                if (isNaN(currentOriginX)) currentOriginX = 0;
                if (isNaN(currentOriginY)) currentOriginY = 0;

                frame.originx = (currentOriginX + offsetX).toString();
                frame.originy = (currentOriginY + offsetY).toString();
                framesModifiedCount++;
            });
        });

        if (framesModifiedCount > 0) {
            drawAllFrameOutlines(); // Visually update frame selections/outlines
            renderFrameEditor();    // Update editor if a frame is selected and its origin changed

            // If an animation is currently playing, restart it to reflect origin changes
            if (currentPlayingAnimationName && animationData.animations[currentPlayingAnimationName]) {
                playAnimationForPreview(currentPlayingAnimationName);
            }
            showSaveStatus(`Applied offset (X: ${offsetX}, Y: ${offsetY}) to ${framesModifiedCount} frame origins. Remember to save.`, "info", 4000);
        } else {
            showSaveStatus("No frames found to apply offset to.", "info", 3000);
        }
    }

    async function saveAnimation() {
        saveStatusMessage.textContent = 'Saving...'; saveStatusMessage.className = 'text-yellow-400 text-center mb-4';
        animationData.imagePath = imagePathInput.value.trim();
        try {
            const response = await fetch(API_ENDPOINT_SAVE, {
                method: 'POST', headers: {'Content-Type': 'application/json'},
                body: JSON.stringify(animationData),
            });
            const result = await response.json();
            if (!response.ok) throw new Error(result.error || `HTTP error ${response.status}`);
            showSaveStatus(result.message || 'Saved successfully!', 'success', 3000);
        } catch (error) {
            console.error('Save error:', error);
            showSaveStatus(`Save failed: ${error.message}`, 'error', 5000);
        }
    }
    
    function showSaveStatus(message, type = 'info', duration = 3000) {
        saveStatusMessage.textContent = message;
        if (type === 'success') saveStatusMessage.className = 'text-green-400 text-center mb-4';
        else if (type === 'error') saveStatusMessage.className = 'text-red-400 text-center mb-4';
        else saveStatusMessage.className = 'text-sky-400 text-center mb-4';
        setTimeout(() => { if (saveStatusMessage.textContent === message) saveStatusMessage.textContent = ''; }, duration);
    }

    function playAnimationForPreview(stateName) {
        if (animationRequestID) cancelAnimationFrame(animationRequestID);
        currentPlayingAnimationName = stateName; currentPlayingFrameIndex = 0;
        elapsedTimeSinceLastFrame = 0; lastTimestamp = 0;
        const animation = animationData.animations[currentPlayingAnimationName];
        if (animation && animation.length > 0) {
            animationRequestID = requestAnimationFrame(animationPreviewLoop);
            currentAnimationInfo.textContent = `Previewing: ${stateName}`;
        } else {
            drawPreviewFrame(null); 
            currentAnimationInfo.textContent = `State "${stateName}" has no frames.`;
        }
    }

    function animationPreviewLoop(timestamp) {
        if (!currentPlayingAnimationName) return;
        const animation = animationData.animations[currentPlayingAnimationName];
        if (!animation || animation.length === 0) { cancelAnimationFrame(animationRequestID); return; }
        if (lastTimestamp === 0) lastTimestamp = timestamp;
        const deltaTime = (timestamp - lastTimestamp) / 1000; lastTimestamp = timestamp;
        elapsedTimeSinceLastFrame += deltaTime;
        const currentFrameData = animation[currentPlayingFrameIndex];
        const frameDuration = parseFloat(currentFrameData.duration);
        if (isNaN(frameDuration) || frameDuration <= 0) { // Treat invalid duration as skippable
            currentPlayingFrameIndex = (currentPlayingFrameIndex + 1) % animation.length;
            elapsedTimeSinceLastFrame = 0; // Reset for the new frame immediately
        } else if (elapsedTimeSinceLastFrame >= frameDuration) {
            elapsedTimeSinceLastFrame -= frameDuration; // Account for overshoot
            currentPlayingFrameIndex = (currentPlayingFrameIndex + 1) % animation.length;
        }
        drawPreviewFrame(animation[currentPlayingFrameIndex]);
        animationRequestID = requestAnimationFrame(animationPreviewLoop);
    }

    function drawPreviewFrame(frameData) {
        previewCtx.clearRect(0, 0, previewCanvas.width, previewCanvas.height);
        previewCtx.imageSmoothingEnabled = false;

        if (previewTileLoaded && previewTileImage.complete && previewTileImage.naturalWidth > 0) {
            const tileW = previewTileImage.naturalWidth;
            const tileH = previewTileImage.naturalHeight;
            const tileX = (previewCanvas.width / 2) - (tileW / 2) + previewTileOffsetX;
            const tileY = (previewCanvas.height / 2) - (tileH / 2) + previewTileOffsetY;
            previewCtx.drawImage(previewTileImage, tileX, tileY, tileW, tileH);
        } else {
            previewCtx.fillStyle = '#2D3748';
            previewCtx.fillRect(0, 0, previewCanvas.width, previewCanvas.height);
        }
        
        previewCtx.strokeStyle = 'rgba(255, 255, 255, 0.3)';
        previewCtx.lineWidth = 1;
        previewCtx.beginPath();
        previewCtx.moveTo(previewCanvas.width / 2, 0);
        previewCtx.lineTo(previewCanvas.width / 2, previewCanvas.height);
        previewCtx.moveTo(0, previewCanvas.height / 2);
        previewCtx.lineTo(previewCanvas.width, previewCanvas.height / 2);
        previewCtx.stroke();


        if (!loadedSpritesheetSource.complete || loadedSpritesheetSource.naturalWidth === 0) return; 
        if (!frameData) { 
            return; 
        }

        try {
            const x = parseFloat(frameData.x), y = parseFloat(frameData.y), w = parseFloat(frameData.w), h = parseFloat(frameData.h),
                  ox = parseFloat(frameData.originx || '0'), oy = parseFloat(frameData.originy || '0'),
                  flip = (frameData.flipx === '1' || frameData.flipx === 1 || frameData.flipx === true);
            if ([x,y,w,h,ox,oy].some(isNaN) || w <= 0 || h <= 0) { return; }
            
            previewCtx.save();
            previewCtx.translate(previewCanvas.width / 2, previewCanvas.height / 2);
            if (flip) previewCtx.scale(-1, 1);
            previewCtx.imageSmoothingEnabled = false; 
            previewCtx.drawImage(loadedSpritesheetSource, x, y, w, h, -ox, -oy, w, h);
            previewCtx.restore();
        } catch (e) { 
            console.error("Error drawing preview frame:", e); 
        }
    }

    saveAnimationButton.addEventListener('click', saveAnimation);
    imagePathInput.addEventListener('change', () => {
        animationData.imagePath = imagePathInput.value.trim();
        loadAndDisplaySpritesheet(); 
        showSaveStatus("Image path changed. Remember to save.", "info", 3000);
    });
    addAnimationStateButton.addEventListener('click', addNewAnimationState);
    addFrameButton.addEventListener('click', addNewFrame);

    initializeEditor();
});
--[[
-- Terminal Glasses Bridge API
--
-- Developped by icewindow
--
-- Tested using the following versions
--  ComputerCraft 1.73
--  OpenPeripheral Core 1.1.1
--  OpenPeripheral Integration 0.2.2
--  OpenPeripheral Addons 0.3.1
--]]


local types = {
  diagram = "diagram",
  bargraph = "bargraph",
  terminal = "terminal",
  bitmap = "bitmap"
}

-- Keeping track of elements
local enhancedElements = {}

local vanillaColors = {
  [colors.white]      = 0xF0F0F0,
  [colors.orange]     = 0xF2B233,
  [colors.magenta]    = 0xE57FD8,
  [colors.lightBlue]  = 0x99B2F2,
  [colors.yellow]     = 0xDEDE6C,
  [colors.lime]       = 0x7FCC19,
  [colors.pink]       = 0xF2B2CC,
  [colors.gray]       = 0xC4C4C4,
  [colors.lightGray]  = 0x999999,
  [colors.cyan]       = 0x4C99B2,
  [colors.purple]     = 0xB266E5,
  [colors.blue]       = 0x3366CC,
  [colors.brown]      = 0x7F664C,
  [colors.green]      = 0x57A64E,
  [colors.red]        = 0xCC4C4C,
  [colors.black]      = 0x000000,
}

--[[
 Crates a diagram on the surface
  param nPosx
    X position of the upper-left corner
  param nPosy
    Y position of the upper-left corner
  param nWidth
    Diagram width
  param nHeight
    Diagram height
  param nDataColor
    (Optional) Color to draw the data in. Defaults to blue (0x0000FF)
  param nDataOpacity
    (Optional) Opacity for the data points. Defaults to 1 (100% opaque)
  param bBar
    (Optional) If true, diagram data will be plotted as bars. If false, only points will be drawn. Defaults to true.
  param bReverse
    (Optional) If true, the Y-axis will be rendered on the right side of the diagram and data will be filled right-to-left. Defaults to false
  param nMarkerSpaceX
    (Optional) Spacing between the markers on X axis. Must be 0 or greater if provided. 0 means no marker.
    If omitted or set to false the diagram will be drawn without diagram surface or axis (dummy diagram) and any following parameters will be ignored.
  param nMarkerSpaceY
    Spacing between markers on Y axis. Must be 0 or greater. 0 means no markers.
  param nDiagramColor
    (Optional) Color of the diagram axis. Defaults to black (0x000000)
  param nAxisOpacity
    (Optional) Axis opacity. Defaults to 1 (100% opaque)
  param nSurfaceOpacity
    (Optional) Opacity of the diagram surface. Defaults to half of nAxisOpacity
--]]
local function addDiagram( oSurface, nPosx, nPosy, nWidth, nHeight, nDataColor, nDataOpacity, bBar, bReverse, nMarkerSpaceX, nMarkerSpaceY, nDiagramColor, nAxisOpacity, nSurfaceOpacity )
  if type(oSurface) ~= "table" or
     type(nPosx) ~= "number" or
     type(nPosy) ~= "number" or
     type(nWidth) ~= "number" or
     type(nHeight) ~= "number" or
     (nDataColor ~= nil and type(nDataColor) ~= "number") or
     (nDataOpacity ~= nil and type(nDataOpacity) ~= "number") or
     (bBar ~= nil and type(bBar) ~= "boolean") or
     (bReverse ~= nil and type(bReverse) ~= "boolean") or
     (nMarkerSpaceX ~= nil and type(nMarkerSpaceX) ~= "number") or
     (nMarkerSpaceX ~= nil and type(nMarkerSpaceY) ~= "number") or
     (nDiagramColor ~= nil and type(nDiagramColor) ~= "number") or
     (nAxisOpacity ~= nil and type(nAxisOpacity) ~= "number") or
     (nSurfaceOpacity ~= nil and type(nSurfaceOpacity) ~= "number") then
      error("Expected object, number, number, number, number, [number], [number], [boolean], [boolean], [[number, number], [number], [number], [number]]")
  end
  
  -- Setup defaults
  nDataColor = nDataColor or 0xFF
  nDataOpacity = nDataOpacity or 1
  if bBar == nil then bBar = true end
  if bReverse == nil then bReverse = false end
  nDiagramColor = nDiagramColor or 0
  nAxisOpacity = nAxisOpacity or 1
  nSurfaceOpacity = nSurfaceOpacity or nAxisOpacity * 0.5
  
  -- Setup locals
  local elements = {
    markerX = {},
    markerY = {},
    bars = {}
  }
  local bVisible = true
  local tData = {}
  local bNormalize = true
  local nNormalizeScale = nHeight
  local tgbid = #enhancedElements + 1
  local userdata

  -- Setup
  if nMarkerSpaceX then
    -- Draw diagram body
    elements[1] = oSurface.addBox(nPosx + (not bReverse and 2 or 0), nPosy, nWidth, nHeight, nDiagramColor, nSurfaceOpacity)
    elements[2] = oSurface.addBox(nPosx + (not bReverse and 2 or 0), nPosy + nHeight, nWidth, 1, nDiagramColor, nAxisOpacity)
    elements[3] = oSurface.addBox(nPosx + (bReverse and nWidth or 1), nPosy, 1, nHeight + 1, nDiagramColor, nAxisOpacity)
    for i=1, 3 do
      elements[i].setUserdata({_tgbid = tgbid})
    end
    if nMarkerSpaceX > 0 then
      for i=0, nWidth, nMarkerSpaceX do
        local box = oSurface.addBox(nPosx + (bReverse and 0 or 1) + i, nPosy + nHeight + 1, 1, 1, nDiagramColor, nAxisOpacity)
        box.setUserdata({_tgbid = tgbid});
        table.insert(elements.markerX, box)
      end
    end
    if nMarkerSpaceY > 0 then
      for i=nHeight, 0, -nMarkerSpaceY do
        local box = oSurface.addBox(nPosx + (bReverse and nWidth + 1 or 0), nPosy + i, 1, 1, nDiagramColor, nAxisOpacity)
        box.setUserdata({_tgbid = tgbid});
        table.insert(elements.markerY, box)
      end
    end
    for i=1, #elements do
      elements[i].setUserdata({_tgbid = tgbid})
    end
  end
  for i=1,nWidth do
    elements.bars[i] = oSurface.addBox(nPosx, nPosy, 1, 0, nDataColor, nDataOpacity)
    elements.bars[i].setUserdata({_tgbid = tgbid})
  end
  
  -- Helper functions
  local function updateDiagram()
    local start  = bReverse and nWidth or 1
    local finish = bReverse and 1 or nWidth
    local step   = bReverse and -1 or 1
    local i = 1
    
    for c=start,finish,step do
      local value = tData[i]
      if value then
        if bNormalize then
          value = (value / nNormalizeScale) * nHeight
        end
        value = math.floor(value + 0.5)
        local barStart = nPosy + nHeight - value
        elements.bars[i].setX(nPosx + (bReverse and -1 or 1) + c)
        elements.bars[i].setY(barStart)
        if bBar then
          elements.bars[i].setHeight(value)
        else
          elements.bars[i].setHeight(value == 0 and 0 or 1)
        end
      end
      i = i + 1
    end
  end
  
  -- Diagram implementation
  local diagram = {}
  
  function diagram.delete()
    for i=1, #elements do
      elements[i].delete()
    end
    for i=1, #elements.markerX do
      elements.markerX[i].delete()
    end
    for i=1, #elements.markerY do
      elements.markerY[i].delete()
    end
    for i=1, #elements.bars do
      elements.bars[i].delete()
    end
  end
  
  function diagram.setVisible( bVis )
    for i=1, #elements do
      elements[i].setVisible(bVis)
    end
    for i=1, #elements.markerX do
      elements.markerX[i].setVisible(bVis)
    end
    for i=1, #elements.markerY do
      elements.markerY[i].setVisible(bVis)
    end
    for i=1, #elements.bars do
      elements.bars[i].setVisible(bVis)
    end
    bVisible = bVis
  end
  
  function diagram.setNormalize( bNewNormalize )
    bNormalize = bNewNormalize
    updateDiagram()
  end
  
  function diagram.setNormalizeScale( nNewNormalizeScale )
    nNormalizeScale = nNewNormalizeScale
    updateDiagram()
  end
  
  function diagram.setX( nNewx )
    if nMarkerSpaceX then
      elements[1].setX(nNewx + (not bReverse and 2 or 0))
      elements[2].setX(nNewx + (not bReverse and 2 or 0))
      elements[3].setX(nNewx + (bReverse and nWidth or 1))
    end
    for i=1,#elements.markerX do
      elements.markerX[i].setX(nNewx + (bReverse and 0 or 1) + (i - 1) * nMarkerSpaceX)
    end
    for i=1,#elements.markerY do
      elements.markerY[i].setX(nNewx + (bReverse and nWidth + 1 or 0))
    end
    nPosx = nNewx
    updateDiagram()
  end
  
  function diagram.setY( nNewy )
    if nMarkerSpaceX then
      elements[1].setY(nNewy)
      elements[2].setY(nNewy + nHeight)
      elements[3].setY(nNewy)
    end
    for i=1,#elements.markerX do
      elements.markerX[i].setY(nNewy + nHeight + 1)
    end
    for i=1,#elements.markerY do
      elements.markerY[i].setY(nNewy + (i - 1) * nMarkerSpaceY)
    end
    nPosy = nNewy
    updateDiagram()
  end
  
  function diagram.setZ( nPosz )
    for i=1, #elements do
      elements[i].setZ(nPosz)
    end
    for i=1, #elements.markerX do
      elements.markerX[i].setZ(nPosz)
    end
    for i=1, #elements.markerY do
      elements.markerY[i].setZ(nPosz)
    end
    for i=1, #elements.bars do
      elements.bars[i].setZ(nPosz)
    end
  end
  
  function diagram.getX()
    return nPosx
  end
  
  function diagram.getY()
    return nPosy
  end
  
  function diagram.getVisible()
    return bVisible
  end
  
  function diagram.setUserdata( data )
    userdata = data
  end
  
  function diagram.getUserdata()
    return userdata
  end
  
  function diagram.getData()
    return tData
  end
  
  function diagram.getType()
    return types.diagram
  end
  
  function diagram.insertAtStart( nValue )
    table.remove(tData, nWidth)
    table.insert(tData, 1, nValue)
    updateDiagram()
  end
  
  function diagram.insertAtEnd( nValue )
    table.remove(tData, 1)
    table.insert(tData, nValue)
    updateDiagram()
  end
  
  return diagram
end

--[[
 Add a bargraph to the surface
  param oSurface
    The surface to create the bargraph on
  param nPosx
    X position of the bargraph
  param nPosy
    Y position of the bargraph
  param nWidth
    Thickness of the bargraph. Must be 1 or greater
  param nMaxValue
    The maximal value the graph can display. Must be 1 or greater
  param bVertical
    If true the bar will be rendered vertical instead of horizontal
  param bReverse
    If true the graph will start at the highest extreme and go towards the lowest extreme
  param nBorderColor
    Color of the border. Defaults to black (0x000000)
  param nBorderOpacity
    Opacity of the border. Defaults to 1 (100% opaque)
  param nFillColor
    Color of the bar. Defaults to white (0xFFFFFF)
  param nFillOpacity
    Opacity of the bar. Defaults to 1 (100% opaque)
  param nFillBackgroundColor
    Color of the "negative" bar. Defaults to black (0x000000)
  param nFillBackgroundOpacity
    Opacity of the "negative" bar. Defaults to 0.5 (50% transparent)
--]]
function addBargraph( oSurface, nPosx, nPosy, nWidth, nMaxValue, bVertical, bReverse, nBorderColor, nBorderOpacity, nFillColor, nFillOpacity, nFillBackgroundColor, nFillBackgroundOpacity )
  if type(oSurface) ~= "table" or
     type(nPosx) ~= "number" or
     type(nPosy) ~= "number" or
     type(nWidth) ~= "number" or
     type(nMaxValue) ~= "number" or
     type(bVertical) ~= "boolean" or
     type(bReverse) ~= "boolean" or
     (nColor ~= nil and type(nColor) ~= "number") or
     (nOpacity ~= nil and type(nOpacity) ~= "number") or
     (nFillColor ~= nil and type(nFillColor) ~= "number") or
     (nFillOpacity ~= nil and type(nFillOpacity) ~= "number") then
      error("Expected object, number, number, number, number, boolean, boolean, [number], [number], [number], [number], [number], [number]")
  end
  -- Setup defaults
  nBorderColor = nBorderColor or 0
  nBorderOpacity = nBorderOpacity or 1
  nFillColor = nFillColor or 0xFFFFFF
  nFillOpacity = nFillOpacity or 1
  nFillBackgroundColor = nFillBackgroundColor or 0
  nFillBackgroundOpacity = nFillBackgroundOpacity or 0.5
  nWidth = nWidth < 1 and 1 or nWidth
  nMaxValue = nMaxValue < 1 and 1 or nMaxValue
  
  -- Setup locals
  local nValue = 0
  local tBorder = {}
  local oFill
  local oNegativeFill
  local bVisible = true
  local tgbid = #enhancedElements + 1
  local userdata
  
  -- Helper function
  local function adjustFill()
    if bVertical and bReverse then
      oFill.setX(nPosx + 1)
      oFill.setY(nPosy + 1)
      oFill.setRotation(0)
      oNegativeFill.setX(nPosx + nWidth + 1)
      oNegativeFill.setY(nPosy + nMaxValue + 1)
      oNegativeFill.setRotation(180)
    elseif bVertical and not bReverse then
      oFill.setX(nPosx + nWidth + 1)
      oFill.setY(nPosy + nMaxValue + 1)
      oFill.setRotation(180)
      oNegativeFill.setX(nPosx + 1)
      oNegativeFill.setY(nPosy + 1)
      oNegativeFill.setRotation(0)
    elseif not bVertical and bReverse then
      oFill.setX(nPosx + nMaxValue + 1)
      oFill.setY(nPosy + 1)
      oFill.setRotation(90)
      oNegativeFill.setX(nPosx + 1)
      oNegativeFill.setY(nPosy + nWidth + 1)
      oNegativeFill.setRotation(270)
    else
      oFill.setX(nPosx + 1)
      oFill.setY(nPosy + nWidth + 1)
      oFill.setRotation(270)
      oNegativeFill.setX(nPosx + nMaxValue + 1)
      oNegativeFill.setY(nPosy + 1)
      oNegativeFill.setRotation(90)
    end
  end
  
  local function adjustBorder()
    tBorder[1].setWidth((bVertical and nWidth or nMaxValue) + 2)
    tBorder[2].setHeight(bVertical and nMaxValue or nWidth)
    tBorder[3].setY(nPosy + (bVertical and nMaxValue or nWidth) + 1)
    tBorder[3].setWidth((bVertical and nWidth or nMaxValue) + 2)
    tBorder[4].setX(nPosx + (bVertical and nWidth or nMaxValue) + 1)
    tBorder[4].setHeight(bVertical and nMaxValue or nWidth)
  end
  
  local function repositionBorder()
    tBorder[1].setX(nPosx)
    tBorder[1].setY(nPosy)
    tBorder[2].setX(nPosx)
    tBorder[2].setY(nPosy + 1)
    tBorder[3].setX(nPosx)
    tBorder[3].setY(nPosy + (bVertical and nMaxValue or nWidth) + 1)
    tBorder[4].setX(nPosx + (bVertical and nWidth or nMaxValue) + 1)
    tBorder[4].setY(nPosy + 1)
  end
  
  -- Element implementation
  local graph = {}
  
  function graph.delete()
    for i=1,4 do
      tBorder[i].delete()
    end
    oFill.delete()
    oNegativeFill.delete()
  end
  
  function graph.setVisible( bVis )
    for i=1,4 do
      tBorder[i].setVisible(bVis)
    end
    oFill.setVisible(bVis)
    oNegativeFill.setVisible(bVis)
    bVisible = bVis
  end
  
  function graph.getVisible()
    return bVisible
  end
  
  function graph.getType()
    return types.bargraph
  end
  
  function graph.setValue( nNewValue )
    nNewValue = nNewValue <= nMaxValue and nNewValue or nMaxValue
    nNewValue = nNewValue < 0 and 0 or nNewValue
    nValue = nNewValue
    oFill.setHeight(nNewValue)
    oNegativeFill.setHeight(nMaxValue - nNewValue)
  end
  
  function graph.setVertical( bNewVertical )
    if bVertical ~= bNewVertical then
      bVertical = bNewVertical
      adjustBorder()
      adjustFill()
    end
  end
  
  function graph.setReverse( bNewReverse )
    if bReverse ~= bNewReverse then
      bReverse = bNewReverse
      adjustFill()
    end
  end
  
  function graph.setX( nNewX )
    nPosx = nNewX
    repositionBorder()
    adjustFill()
  end
  
  function graph.setY( nNewY )
    nPosy = nNewY
    repositionBorder()
    adjustFill()
  end
  
  function graph.setWidth( nNewWidth )
    nWidth = nNewWidth < 1 and 1 or nNewWidth
    oFill.setWidth(nWidth)
    oNegativeFill.setWidth(nWidth)
    adjustBorder()
    adjustFill()
  end
  
  function graph.setMaxValue( nNewMaxValue )
    nMaxValue = nNewMaxValue < 1 and 1 or nNewMaxValue
    adjustBorder()
    adjustFill()
    graph.setValue(nValue)
  end
  
  function graph.setBorderColor( nNewColor )
    for i=1,4 do
      tBorder.setColor(nNewColor)
    end
    nBorderColor = nNewColor
  end
  
  function graph.setBorderOpacity( nNewOpacity )
    for i=1,4 do
      tBorder.setOpacity(nNewOpacity)
    end
    nBorderOpacity = nNewOpacity
  end
  
  function graph.setFillColor( nNewColor )
    oFill.setColor(nNewColor)
    nFillColor = nNewColor
  end
  
  function graph.setFillOpacity( nNewOpacity )
    oFill.setOpacity(nNewOpacity)
    nFillOpacity = nNewOpacity
  end
  
  function graph.setFillBackgroundColor( nNewColor )
    oNegativeFill.setColor(nNewColor)
    nFillBackgroundColor = nNewColor
  end
  
  function graph.setFillBackgroundOpacity( nNewOpacity )
    oNegativeFill.setOpacity(nNewOpacity)
    nFillBackgroundOpacity = nNewOpacity
  end
  
  function graph.getX()
    return nPosx
  end
  
  function graph.getY()
    return nPosy
  end
  
  function graph.setUserdata( data )
    userdata = data
  end
  
  function graph.getUserdata()
    return userdata
  end
  
  function graph.getValue()
    return nValue
  end
  
  function graph.getMaxValue()
    return nMaxValue
  end
  
  function graph.getWidth()
    return nWidth
  end
  
  function graph.isReverse()
    return bReverse
  end
  
  function graph.isVertical()
    return bVertical
  end
  
  function graph.getBorderColor()
    return nBorderColor
  end
  
  function graph.getBorderOpacity()
    return nBorderOpacity
  end
  
  function graph.getFillColor()
    return nFillColor
  end
  
  function graph.getFillOpacity()
    return nFillOpacity
  end
  
  function graph.getFillBackgroundColor()
    return nFillBackgroundColor
  end
  
  function graph.getFillBackgroundOpacity()
    return nFillBackgroundOpacity
  end
  
  -- Build graph
  tBorder[1] = oSurface.addBox(nPosx, nPosy, (bVertical and nWidth or nMaxValue) + 2, 1, nBorderColor, nBorderOpacity)  -- top horizontal
  tBorder[2] = oSurface.addBox(nPosx, nPosy + 1, 1, bVertical and nMaxValue or nWidth, nBorderColor, nBorderOpacity) -- left vertical
  tBorder[3] = oSurface.addBox(nPosx, nPosy + (bVertical and nMaxValue or nWidth) + 1, (bVertical and nWidth or nMaxValue) + 2, 1, nBorderColor, nBorderOpacity) -- bottom horizontal
  tBorder[4] = oSurface.addBox(nPosx + (bVertical and nWidth or nMaxValue) + 1, nPosy + 1, 1, bVertical and nMaxValue or nWidth, nBorderColor, nBorderOpacity) -- right vertical
  -- Add proto boxes for the fill
  oFill = oSurface.addBox(0, 0, nWidth, 0, nFillColor, nFillOpacity)
  oNegativeFill = oSurface.addBox(0, 0, nWidth, nMaxValue, nFillBackgroundColor, nFillBackgroundOpacity)
  adjustFill()
  
  for i=1, 4 do
    tBorder.setUserdata({_tgbid = tgbid})
  end
  oFill.setUserdata({_tgbid = tgbid})
  oNegativeFill.setUserdata({_tgbid = tgbid})
  
  return graph
end

--[[
 Creates a terminal display object
  param oSurface
    The surface to create the terminal on
  param nPosx
    X coordinate of the terminal
  param nPosy
    Y coordinate of the terminal
  param nChars
    Number of characters in one row
  param nRows
    Number ow rows on the terminal
  param nTextColor
    (Optional) Text color. Defaults to vanilla white (0xF0F0F0)
  param nBackgroundColor
    (Optional) Background color. Defaults to black (0x000000)
  param nTextOpacity
    (Optional) Opacity of the terminal text. Defaults to 1 (100% opaque)
  param nBackgroundOpacity
    (Optional) Opacity of the terminal background. Defaults to 0.5 (50% opaque)
--]]
local function addTerminal( oSurface, nPosx, nPosy, nChars, nRows, nTextColor, nBackgroundColor, nTextOpacity, nBackgroundOpacity )
  if type(oSurface) ~= "table" or
     type(nPosx) ~= "number" or
     type(nPosy) ~= "number" or
     type(nChars) ~= "number" or
     type(nRows) ~= "number" or
     (nTextColor ~= nil and type(nTextColor) ~= "number") or
     (nBackgroundColor ~= nil and type(nBackgroundColor) ~= "number") or
     (nTextOpacity ~= nil and type(nTextOpacity) ~= "number") or
     (nBackgroundOpacity ~= nil and type(nBackgroundOpacity) ~= "number") then
      error("Expected object, number, number, number, number, [number], [number], [number], [number]")
  end
  
  local charWidth = 6
  local charHeight = 9
  local width = nChars * charWidth + 1
  local height = nRows * charHeight
  nTextColor = nTextColor or 0xF0F0F0
  nBackgroundColor = nBackgroundColor or 0
  nTextOpacity = nTextOpacity or 1
  nBackgroundOpacity = nBackgroundOpacity or 0.5
  
  local elements = {}
  local lineBuffer = {}
  local nCursorX = 1
  local nCursorY = 1
  local cursor = oSurface.addBox(nPosx, nPosy + charHeight, charWidth + 1, 1, nTextColor, nTextOpacity)
  local cursorBlink = true
  local visible = true
  local textProcessing = false
  local doScreenUpdates = false
  local tgbid = #enhancedElements + 1
  local userdata
  
  -- Setup
  for i=1,nRows do
    local lineElements = {}
    local lineChars = {}
    for j=1,nChars do
      lineElements[j] = {
        oSurface.addBox(nPosx + (j - 1) * charWidth, nPosy + (i - 1) * charHeight , charWidth, charHeight, nBackgroundColor, nBackgroundOpacity),
        oSurface.addText(nPosx + (j - 1) * charWidth + 1, nPosy + (i - 1) * charHeight + 1, " ", nTextColor)
      }
      lineElements[j][1].setZ(0)
      lineElements[j][2].setZ(1)
      lineElements[j][2].setAlpha(nTextOpacity)
      
      lineChars[j] = {" ", nBackgroundColor, nTextColor}
    end
    elements[i] = lineElements    
    lineBuffer[i] = lineChars
  end
  cursor.setZ(2)
  
  -- helper functions
  local function numberToRGB( nColor )
    local red = bits.rshift(nColor, 16)
    local green = bits.rshift(bits.band(nColor, 0xFF00), 8)
    local blue = bits.band(nColor(nColor, 0xFF))
    return red, green, blue
  end
  
  local function postScreenUpdate()
    if doScreenUpdates then
      if oSurface.sync and type(oSurface.sync) == "function" then
        oSurface.sync()
      else
        os.queueEvent("tgb_update")
      end
    end
  end
  
  local function updateCursorPos()
    cursor.setX( nPosx + (nCursorX - 1) * charWidth )
    cursor.setY( nPosy + nCursorY * charHeight )
  end
  
  local function updateCursorColor()
    if nCursorX >= 1 and nCursorX <= nChars and nCursorY >= 1 and nCursorY <= nRows then
      cursor.setColor(lineBuffer[nCursorY][nCursorX][3])
      postScreenUpdate()
    end
  end
  
  local function updateScreen()
    for i=1,#lineBuffer do
      local row = lineBuffer[i]
      for j=1,#row do
        local column = row[j]
        local pixel = elements[i][j]
        pixel[1].setColor(column[2])
        pixel[2].setColor(column[3])
        pixel[2].setText(column[1])
      end
    end
  end
  
  -- Terminal implementation
  local term = {}
  
  function term.delete()
    for i=1,#elements do
      local elementsRow = elements[i]
      for j=1,#elementsRow do
        elementsRow[j][1].delete()
        elementsRow[j][2].delete()
      end
    end
    cursor.delete()
  end
  
  function term.clear()
    for i=1,nRows do
      for j=1,nChars do
        lineBuffer[i][j] = {" ", nBackgroundColor, nTextColor}
      end
    end
    if visible then
      updateScreen()
      updateCursorColor()
      postScreenUpdate()
    end
  end

  function term.clearLine()
    if nCursorY >= 1 and nCursorY <= nRows then
      for i=1,nChars do
        lineBuffer[nCursorY][i] = {" ", nBackgroundColor, nTextColor}
      end
      if visible then
        updateScreen()
        updateCursorColor()
        updateCursorPos()
      end
    end
  end

  function term.getCursorPos()
    return nCursorX, nCursorY
  end

  function term.setCursorPos( x, y )
    nCursorX = math.floor( x )
    nCursorY = math.floor( y )
    if visible then
      updateCursorPos()
      updateCursorColor()
      postScreenUpdate()
    end
  end

  function term.setCursorBlink( blink )
    cursorBlink = blink
    cursor.setVisible(blink)
  end

  function term.isColor()
    return true
  end

  function term.isColour()
    return true
  end

  local function setTextColor( color, tgbcolor )
    if tgbcolor then
      nTextColor = color
    else
      if vanillaColors[color] == nil then
        error("Illegal color! Set second parameter to true to set custom color!")
      end
      nTextColor = vanillaColors[color]
    end
    cursor.setColor(nTextColor)
  end

  function term.setTextColor( color, tgbcolor )
    setTextColor( color, tgbcolor )
  end

  function term.setTextColour( color, tgbcolor )
    setTextColor( color, tgbcolor )
  end

  local function setBackgroundColor( color, tgbcolor )
    if tgbcolor then
      nBackgroundColor = color
    else
      if vanillaColors[color] == nil then
        error("Illegal color! Set second parameter to true to set custom color!")
      end
      nBackgroundColor = vanillaColors[color]
    end
  end

  function term.setBackgroundColor( color, tgbcolor )
    setBackgroundColor( color, tgbcolor )
  end

  function term.setBackgroundColour( color, tgbcolor )
    setBackgroundColor( color, tgbcolor )
  end

  function term.getSize()
      return nChars, nRows
  end
  
  function term.getVisible()
    return visible
  end

  function term.scroll( n )
    for i=1,n do
      table.remove(lineBuffer, 1)
      local newLine = {}
      for j=1,nChars do
        newLine[j] = {" ", nBackgroundColor, nTextColor}
      end
      table.insert(lineBuffer, newLine)
    end
    
    if visible then
      updateScreen()
      updateCursorColor()
      updateCursorPos()
      postScreenUpdate()
    end
  end
  
  function term.setVisible( bVis )
    visible = bVis
    for i=1,#elements do
      for j=1,#elements[i] do
        elements[i][j][1].setVisible(bVis)
        elements[i][j][2].setVisible(bVis)
      end
    end
    if visible then
      updateScreen()
      updateCursorPos()
      updateCursorColor()
      postScreenUpdate()
    end
  end
  
  function term.getType()
    return types.terminal
  end
  
  function term.setTextProcessing( bProcessing )
    textProcessing = bProcessing
  end
  
  function term.isTextProcessing()
    return textProcessing
  end
  
  function term.setDoScreenUpdate( bUpdate )
    doScreenUpdates = bUpdate
  end
  
  function term.isDoingScreenUpdates()
    return doScreenUpdates
  end
  
  function term.write( sLine )
    local w,h = term.getSize()
    
    local function newLine()
      if nCursorY >= h then
        scroll(1)
        nCursorY = nCursorY - 1
      end
      term.setCursorPos(1, nCursorY + 1)
    end
    
    local function write( data )
      local row = lineBuffer[nCursorY]
      local cur = 1
      while data:len() > 0 do
        local column = row[nCursorX]
        column[1] = data:sub(1,1)
        column[2] = nBackgroundColor
        column[3] = nTextColor
        nCursorX = nCursorX + 1
        data = data:sub(2)
        if nCursorX > w then
          newLine()
          row = lineBuffer[nCursorY]
        end
      end
    end
    
    local data = tostring(sLine)
    while data:len() > 0 do
      
      if textProcessing then
        -- Don't try to process 1 character long strings
        if data:len() == 1 then
          write(data)
          data = data:sub(2)
        end
        
        -- Minecraft text color code &[0-9A-F]
        local fcolor = data:match("^&.")
        if fcolor then
          if data:match("^&[%x&]") then
            fcolor = fcolor:sub(2)
            if fcolor == "&" then
              write(fcolor)
            else
              term.setTextColor(math.pow(2, tonumber(fcolor, 16)))
            end
            data = data:sub(3)
          else
            write(fcolor)
            data = data:sub(2)
          end
        end
        
        -- Minecraft background color code $[0-9A-F]
        local bcolor = data:match("^%$.")
        if bcolor then
          if data:match("^%$[%x%$]") then
            bcolor = bcolor:sub(2)
            if bcolor == "$" then
              write(bcolor)
            else
              term.setBackgroundColor(math.pow(2, tonumber(bcolor, 16)))
            end
          else
            write(bcolor)
          end
          data = data:sub(3)
        end
        
        local acolor = data:match("^%%.......")
        if acolor then
          if data:match("^%%%x%x%x%x%x%x[%$&]") then
            local target = acolor:sub(8,8)
            acolor = acolor:sub(2,7)
            if target == "&" then
              term.setTextColor(tonumber(acolor, 16), true)
            else
              term.setBackgroundColor(tonumber(acolor, 16), true)
            end
          else
            write(acolor)
          end
          data = data:sub(9)
        end
      end
      
      local newline = data:match("^\n")
      if newline then
        newLine()
        data = data:sub(2)
      end
      
      local whitespace = data:match("^[ \t]+")
      if whitespace then
        write(whitespace)
        data = data:sub(whitespace:len() + 1 )
      end
      
      local text
      if textProcessing then
        text = data:match("^[^ \t\n&%$%%]+")
      else
        text = data:match("^[^ \t\n]+")
      end
      if text then
        --print("text ", text)
        data = data:sub(text:len() + 1)
        if text:len() > w then
          while text:len() > 0 do
            if nCursorX > w then
              newLine()
            end
            write(text)
            text = text:sub((w - nCursorX) + 2)
          end
        else
          if nCursorX + text:len() - 1 > w then
            newLine()
          end
          write(text)
        end  
      end
    end
    if visible then
      updateScreen()
      updateCursorPos()
      updateCursorColor()
      postScreenUpdate()
    end
  end
  
  return term
end

--[[
 Creates a bitmap image on the surface
 USE WITH CAUTION! This function has the potential to create tens of thousands of elements on screen, causing at least client-side lag.
 I recommend not using images larger than 200 by 200 pixels, and even that is pushing it.
  param oSurface
    The surface to create the bitmap on
  param nPosx
    X coordinate of the image
  param nPosy
    Y coordinate of the image
  param sBitmapPath
    The file path to the source image file
  param nOpacity
    (Optional) The opacity of the bitmap image
--]]
local function addBitmap( oSurface, nPosx, nPosy, sBitmapPath, nOpacity )
  if type(oSurface) ~= "table" or
     type(nPosx) ~= "number" or
     type(nPosy) ~= "number" or
     type(sBitmapPath) ~= "string" or
     (nOpacity ~= nil and type(nOpacity) ~= "number") then
      error("Expected object, number, number, string, [number]")
  end
  if not fs.exists(sBitmapPath) then
    error("File not found")
  end
  if fs.isDir(sBitmapPath) then
    error("Not a file!")
  end
  
  nOpacity = nOpacity or 1
  
  local pixels = {}
  local image = {}
  local file
  local bVisible = true
  
  -- Helper functions
  local MAXINT, SUB = math.pow(2, 31), math.pow(2, 32)
  
  local function addPixel(x, y, color)
    table.insert(pixels, oSurface.addBox(nPosx + x - 1, nPosy + y - 1, 1, 1, color, nOpacity))
  end
  
  local function readByte()
    return file.read()
  end
  
  local function readWord()
    return file.read()+file.read()*0x100
  end
  
  local function readDWord()
    return file.read()+file.read()*0x100+file.read()*0x10000+file.read()*0x01000000
  end
  
  local function readLong()
    local n = file.read()+file.read()*0x100+file.read()*0x10000+file.read()*0x01000000
    return (n >= MAXINT and n - SUB) or n
  end
  
  local function skip( nBytes )
    for i=1,nBytes do
      file.read()
    end
  end
  
  -- Image implementation
  function image.delete()
    for i=1, #pixels do
      pixels[i].delete()
    end
  end
  
  function image.setX( nNewX )
    for i=1, #pixels do
      local offset = pixels[i].getX() - nPosx
      pixels[i].setX(nNewX + offset)
    end
    nPosx = nNewX
  end
  
  function image.setY( nNewY )
    for i=1, #pixels do
      local offset = pixels[i].getY() - nPosy
      pixels[i].setY(nNewY + offset)
    end
    nPosy = nNewY
  end
  
  function image.setZ( nNewZ )
    for i=1, #pixels do
      pixels[i].setZ(nNewZ)
    end
  end
  
  function image.setOpacity( nNewOpacity )
    for i=1, #pixels do
      pixels[i].setOpacity(nNewOpacity)
    end
    nOpacity = nNewOpacity
  end
  
  function image.setVisible( bVis )
    for i=1, #pixels do
      pixels[i].setVisible(bVis)
    end
    bVisible = bVis
  end
  
  function image.getX()
    return nPosx
  end
  
  function image.getY()
    return nPosy
  end
  
  function image.getOpacity()
    return nOpacity
  end
  
  function image.getVisible()
    return bVisible
  end
  
  function image.closeFile()
    file.close()
  end
  
  -- Build the image
  file = fs.open(sBitmapPath, "rb")
  
  -- Header
  if readWord() ~= 19778 then
    error("Not a bitmap image file!")
  end
  readDWord()  -- bfSize
  readDWord()  -- bfReserved
  local bfOffBits = readDWord()
  
  -- Information block
  local biSize = readDWord()
  local biWidth = readLong()
  local biHeight = readLong()
  readWord()  -- biPlanes
  local biBitCount = readWord()
  local biCompression = readDWord()
  local biSizeImage = readDWord()
  readDWord()  --biXPelsPerMeter
  readDWord()  --biYPelsPerMeter
  local biClrUsed = readDWord()
  local biClrImportant = readDWord()
  
  skip(bfOffBits - 14 - biSize)
  local function drawImage()
    if biBitCount == 24 then
      local padding = (biWidth * 3) % 4
      for y = (biHeight > 0 and biHeight or 1), (biHeight > 0 and 1 or biHeight), (biHeight > 0 and -1 or 1) do
        for x = 1, biWidth do
          local blue = readByte()
          local green = readByte()
          local red = readByte()
          addPixel(x, y, red * 0x10000 + green * 0x100 + blue)
        end
        skip(padding)
      end
    end
  end
  
  --[[
  Large image files have the potential to take too long to add to the surface, thus causing CC to terminate the process.
  To avoid leaving the opened image file unclosed the drawing of the image needs to be done in protected mode.
  Take note, the API will NOT notifiy the user about a failed drawing (other than the fact that the image is incomplete)
  ]]
  pcall(drawImage)
  file.close()
  
  return image
end

-- Enhanced surface
function getEnhancedSurfaceFromSurface( oSurface )
  
  function oSurface.addDiagram(     nPosx, nPosy, nWidth, nHeight, nDataColor, nDataOpacity, bBar, bReverse, nMarkerSpaceX, nMarkerSpaceY, nDiagramColor, nAxisOpacity, nSurfaceOpacity )
    local e = addDiagram( oSurface, nPosx, nPosy, nWidth, nHeight, nDataColor, nDataOpacity, bBar, bReverse, nMarkerSpaceX, nMarkerSpaceY, nDiagramColor, nAxisOpacity, nSurfaceOpacity )
    table.insert(enhancedElements, e)
    return e
  end
  
  function oSurface.addTerminal(     nPosx, nPosy, nChars, nRows, nTextColor, nBackgroundColor, nTextOpacity, nBackgroundOpacity )
    local e = addTerminal( oSurface, nPosx, nPosy, nChars, nRows, nTextColor, nBackgroundColor, nTextOpacity, nBackgroundOpacity )
    table.insert(enhancedElements, e)
    return e
  end
  
  function oSurface.addBargraph(     nPosx, nPosy, nWidth, nMaxValue, bVertical, bReverse, nBorderColor, nBorderOpacity, nFillColor, nFillOpacity, nFillBackgroundColor, nFillBackgroundOpacity )
    local e = addBargraph( oSurface, nPosx, nPosy, nWidth, nMaxValue, bVertical, bReverse, nBorderColor, nBorderOpacity, nFillColor, nFillOpacity, nFillBackgroundColor, nFillBackgroundOpacity )
    table.insert(enhancedElements, e)
    return e
  end
  
  function oSurface.addBitmap(     nPosx, nPosy, sBitmapPath, nOpacity )
    local e = addBitmap( oSurface, nPosx, nPosy, sBitmapPath, nOpacity )
    table.insert(enhancedElements, e)
    return e
  end
  
  return oSurface
end

function getEnhancedSurfaceFromName( oSurfaceProvider, sName )
  if type(oSurfaceProvider) == "string" then
    oSurfaceProvider = peripheral.wrap(oSurfaceProvider)
  end
  if type(oSurfaceProvider) ~= "table" or type(oSurfaceProvider.getSurfaceByName) ~= "function" then
    error("Illegal surface provider!")
  end
  return getEnhancedSurfaceFromSurface(oSurfaceProvider.getSurfaceByName(sName))
end

function getEnhancedSurfaceFromUUID( oSurfaceProvider, sUUID )
  if type(oSurfaceProvider) == "string" then
    oSurfaceProvider = peripheral.wrap(oSurfaceProvider)
  end
  if type(oSurfaceProvider) ~= "table" or type(oSurfaceProvider.getSurfaceByUUID) ~= "function" then
    error("Illegal surface provider!")
  end
  return getEnhancedSurfaceFromSurface(oSurfaceProvider.getSurfaceByUUID(sUUID))
end

-- Other functions
function getAllEnhancedElements()
  return enhancedElements
end

function getEnhancedTypes()
  local eTypes = {}
  local i = 1
  for _,v in pairs(types) do
    eTypes[i] = v
    i = i + 1
  end
  return eTypes
end

local bRunning = false

--[[
 Catch events from the wireless keyboard and builds custom events.
 Should be run in a coroutine.
--]]
function run()
  if bRunning then
    error("TGB is already running!")
  end
  bRunning = true
  
  local e, side, user, uuid, id, onUserSurface, cx, cy, button
  local function getElement()
    local element
    if onUserSurface then
      local surface = peripheral.call(side, "getSurfaceByUUID", uuid)
      element = surface.getById(id)
    else
      element = peripheral.call(side, "getById", id)
    end
    return element
  end
  
  while bRunning do
    e, side, user, uuid, id, onUserSurface, cx, cy, button = os.pullEvent()
    --if e == "glasses_capture" then
    if e == "glasses_component_mouse_down" then
      local elem = getElement()
      local tgbid = elem.getUserdata()._tgbid
      os.queueEvent("tgb_mouse_down", side, user, uuid, tgbid)
    elseif e == "glasses_component_mouse_up" then
      local elem = getElement()
      local tgbid = elem.getUserdata()._tgbid
      os.queueEvent("tgb_mouse_up", side, user, uuid, tgbid)
    end
  end
end
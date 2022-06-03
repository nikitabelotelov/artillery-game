local g <const> = playdate.graphics
local geom <const> = playdate.geometry

-- XXX: the compiler only knows to link the imported file in if the import statement is at the start of the line
local qrencode =
import("CoreLibs/3rdparty/qrencode_panic_mod.lua")

-- was tempted to make this sync function local… but maybe somebody out there needs it for something. still, it's not mentioned in the docs.
function playdate.graphics.generateQRCodeSync( stringToEncode, desiredEdgeDimension )

    -- calculate QR code
    local ok, qrCodeData = qrencode.qrcode( stringToEncode )

    -- error handling
    if not ok then
        local errorMessage = qrCodeData
        print( errorMessage )
        return
    end
    
    return generateQRCodeImage( qrCodeData, desiredEdgeDimension )
    
end

local function generateQRCodeImage( qrCodeData, desiredEdgeDimension )

    local MIN_BLOCK_SIZE <const> = 2
    local OPTIMAL_WIDTH <const> = 100
    local PADDING_WIDTH <const> = 1

    local desiredEdgeDimension = desiredEdgeDimension or OPTIMAL_WIDTH
    local qrCodeDataWidth = #qrCodeData + PADDING_WIDTH * 2
    local blockSize = desiredEdgeDimension // qrCodeDataWidth
    if blockSize < MIN_BLOCK_SIZE then
        blockSize = MIN_BLOCK_SIZE
    end

    -- create image to hold qrcode
    local qrCodeImage = g.image.new( qrCodeDataWidth * blockSize, qrCodeDataWidth * blockSize )

    g.pushContext( qrCodeImage )
    
    -- draw the padding
    g.setColor(g.kColorWhite)
    g.fillRect( 0, 0, qrCodeImage.width, qrCodeImage.height )
    
    -- draw the data
    g.setColor(g.kColorBlack)
    for x = 1, #qrCodeData do
        for y = 1, #qrCodeData[ x ] do

            value = qrCodeData[ x ][ y ]

            local q_x = x - 1 + PADDING_WIDTH
            local q_y = y - 1 + PADDING_WIDTH

            if value > 0 then
                g.fillRect( q_x * blockSize, q_y * blockSize, blockSize, blockSize )
            end
        end
    end
    
    g.popContext()
    
    return qrCodeImage
    
end


local qrCodeTimer = nil

function playdate.graphics.generateQRCode( stringToEncode, desiredEdgeDimension, callback )
    
    assert( callback, "Need to pass a callback as the third argument to generateQRCode()" )
    
    local wrapped = coroutine.wrap(
        function()
            return qrencode.qrcode( stringToEncode )
        end
    )
    
    local MS_PER_FRAME <const> = 1000 // playdate.display.getRefreshRate()
    
    qrCodeTimer = playdate.timer.new( MS_PER_FRAME, 
        function( thisTimer )
            
            local wrappedDone, qrCodeData = wrapped()
            if wrappedDone == true then
                
                -- stop the timer
                thisTimer:remove()
                
                -- generate and return image
                local qrCodeImage = generateQRCodeImage( qrCodeData, desiredEdgeDimension )
                callback( qrCodeImage )
                
            elseif wrappedDone == false then
                
                -- stop the timer
                thisTimer:remove()

                -- error
				callback( nil, qrCodeData ) -- this is the error message
                
            end
        end
    )
    qrCodeTimer.repeats = true
	qrCodeTimer.timerEndedArgs = { qrCodeTimer }
    
    return qrCodeTimer
    
end

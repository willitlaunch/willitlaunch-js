makeGage = (idx, val, min, max, name) ->
  return new JustGage {
    id: "ins#{idx}"
    value: val
    min: min
    max: max
    title: name
    valueFontColor: "#fff"
    showMinMax: false
    gaugeColor: "#333"
    levelColors: ["#44aa44"]
    label: ""
  }

window.gages = {}
window.inputs = {}
window.gageidx = 1
window.polling = false

c = new WebSocket "ws://10.0.1.23:8080/ws"
c.onmessage = (e) ->
    data = JSON.parse e.data
    if 'name' of data
        $('#name').text data.name
    if 'objectives' of data
        list = $('<ul></ul>')
        for objective in data.objectives
            list.append($('<li></li>').text(objective))
        $('#checklist').html(list)
    if 'TimeLeft' of data
        $('#timer').text "T-#{data.TimeLeft}"
    if 'outputWidgets' of data
        for widget in data.outputWidgets
            gid = widget.Gid
            wid = widget.Wid
            my_id = (gid+1) * 100 + (wid+1)
            if my_id not of window.gages
                window.gages[my_id] = makeGage(window.gageidx,
                    widget.Value, widget.Min, widget.Max, widget.Label)
                window.gageidx += 1
                if window.gageidx > 7
                    c.close()
                    console.log "too many things"
            else
                window.gages[my_id].refresh(Math.round(widget.Value))
    if 'inputWidgets' of data
        for widget in data.inputWidgets
            gid = widget.Gid
            wid = widget.Wid
            my_id = (gid+1) * 100 + (wid+1)
            if my_id not of window.inputs
                if widget.Style == "button"
                    window.inputs[my_id] = $("<button></button>").text(widget.Label)
                    $(window.inputs[my_id]).attr('data-gid', gid)
                    $(window.inputs[my_id]).attr('data-wid', wid)
                    $('#controls').append(window.inputs[my_id])
                    $(window.inputs[my_id]).mousedown (e) ->
                        gid = parseInt $(this).attr('data-gid')
                        wid = parseInt $(this).attr('data-wid')
                        msg = {Gid: gid, Wid: wid, Value: true}
                        console.log msg
                        c.send JSON.stringify msg
                    $(window.inputs[my_id]).mouseup (e) ->
                        gid = parseInt $(this).attr('data-gid')
                        wid = parseInt $(this).attr('data-wid')
                        msg = {Gid: gid, Wid: wid, Value: false}
                        console.log msg
                        c.send JSON.stringify msg
                else if widget.Style == "slider"
                    window.inputs[my_id] = $("<input type=range min=#{widget.Min} max=#{widget.Max} value=#{widget.Value}>")
                    $(window.inputs[my_id]).attr('data-gid', gid)
                    $(window.inputs[my_id]).attr('data-wid', wid)
                    $('#controls').append(window.inputs[my_id])
                    $(window.inputs[my_id]).on 'input', (e) ->
                        gid = parseInt $(this).attr('data-gid')
                        wid = parseInt $(this).attr('data-wid')
                        msg = {Gid: gid, Wid: wid, Value: parseInt($(this).val())}
                        console.log msg
                        c.send JSON.stringify msg
                    #window.inputs[my_id] = $("<input type=text value=0 class=dial></input>")
                    #$(window.inputs[my_id]).attr('data-gid', gid)
                    #$(window.inputs[my_id]).attr('data-wid', wid)
                    #$('#controls').append(window.inputs[my_id])
                    #$('.dial').knob {
                        #min: widget.Min
                        #max: widget.Max
                        #step: (widget.Max-widget.Min)/50
                        #cursor: 10
                        #width: "80px"
                        #height: "80px"
                        #angleOffset: -125
                        #angleArc: 250
                        #change: (v) ->
                            #gid = parseInt $(this).closest('input').attr('data-gid')
                            #wid = parseInt $(this).closest('input').attr('data-wid')
                            #console.log $(this)
                            #console.log $(this).closest('input')
                            #msg = {Gid: gid, Wid: wid, Value: v}
                            #console.log msg
                            #c.send JSON.stringify msg
                    #}
    if 'Status' of data
        if data.Status == "FAILED"
            $('#failure').get(0).play()
            alert 'Game Over'
        else if data.Status == "SUCCESS"
            $('#liftoff').get(0).play()
            alert 'You Win'
        else if data.Status == "POLL"
            $('#overlay').fadeIn()
            window.polling = true
            $('#needago').get(0).play()
        else if data.Status == "POLLCONT"
            who = data.ControllerName.split(" ")[0]
            $("##{who}").get(0).play()
            $('#pollcont').text data.ControllerName
        else if data.Status == "NOPOLL"
            $('#overlay').fadeOut()
            window.polling = false

$(document).keydown (e) ->
    if not window.polling
        return
    if e.keyCode == 37
        window.polling = false
        console.log "NO GO"
        $('#nogo').get(0).play()
        window.ws.send '{"Gid": 99, "Wid": 100, "Value": false}'
        $('.votetext').fadeOut()
    else if e.keyCode == 39
        window.polling = false
        console.log "GO"
        n = Math.floor(Math.random() * 3 + 1)
        window.ws.send '{"Gid": 99, "Wid": 100, "Value": true}'
        $("#go#{n}").get(0).play()
        $('.votetext').fadeOut()

window.ws = c

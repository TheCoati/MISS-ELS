const buttons = [
    {
        color: '#b6617a',
        colorActive: '#F183A3',
        event: 'toggleSiren',
    },
    {
        color: '#45a4c4',
        colorActive: '#54C6ED',
        event: 'toggleLightPrimary',
    },
    {
        color: '#c0a74f',
        colorActive: '#FDDB69',
        event: 'toggleLightWarning',
    },
    {
        color: '#9f9f9f',
        colorActive: '#FFFFFF',
        event: 'toggleLightSecondary',
    },
    {
        color: '#497e45',
        colorActive: '#70C169',
        event: 'toggleLightStatic1',
    },
    {
        color: '#9f9f9f',
        colorActive: '#FFFFFF',
        event: 'toggleLightStatic2',
    },
]

const root = document.getElementById('honac')
const container = document.getElementById('honac_container')

window.addEventListener('message', (event) => {
    if (event.data.event === 'show') {
        root.style.display = 'block'
    }

    if (event.data.event === 'hide') {
        root.style.display = 'none'
    }
})

for(let i = 0; i < buttons.length; i++) {
    const buttonData = buttons[i]

    const frame = document.createElement('div')
    frame.classList.add('button_frame')

    const button = document.createElement('button')
    button.classList.add('button')
    button.style.borderColor = buttonData.colorActive
    //

    button.addEventListener('click', () => {
        fetch(`https://${GetParentResourceName()}/toggle`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({
                event: buttonData.event
            })
        })

        const audio = new Audio('sounds/beep.ogg')
        audio.volume = 0.2
        audio.play()

        // if (!button.dataset.on) {
        //     button.dataset.on = true
        //     button.style.boxShadow = `0 0 4px 4px ${buttonData.colorActive}`
        //     button.style.borderColor = buttonData.colorActive
        // } else {
        //     delete button.dataset.on
        //     button.style.boxShadow = ''
        //     button.style.borderColor = buttonData.color
        // }
    })

    frame.appendChild(button)
    container.appendChild(frame)
}

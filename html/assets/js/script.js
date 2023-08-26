let timeout = false

const BUTTONS = [{
    color: '#b6617a',
    colorActive: '#F183A3',
    event: 'toggleSiren',
}, {
    color: '#45a4c4',
    colorActive: '#54C6ED',
    event: 'toggleLightPrimary',
}, {
    color: '#c0a74f',
    colorActive: '#FDDB69',
    event: 'toggleLightWarning',
}, {
    color: '#9f9f9f',
    colorActive: '#FFFFFF',
    event: 'toggleLightSecondary',
}, {
    color: '#497e45',
    colorActive: '#70C169',
    event: 'toggleLightStatic1',
}, {
    color: '#9f9f9f',
    colorActive: '#FFFFFF',
    event: 'toggleLightStatic2',
}]

const root = document.getElementById('honac')
const container = document.getElementById('honac_container')

for(let i = 0; i < BUTTONS.length; i++) {
    const buttonData = BUTTONS[i]

    const frame = document.createElement('div')
    frame.classList.add('button_frame')

    const button = document.createElement('button')
    button.classList.add('button')
    button.style.borderColor = buttonData.colorActive

    button.addEventListener('click', async () => {
        if (timeout) {
            return
        }

        timeout = true

        setTimeout(() => timeout = false, 500)

        const audio = new Audio('assets/sounds/beep.ogg')
        audio.volume = 0.05

        setTimeout(() =>  audio.play().then(), 1)

        fetch(`https://${GetParentResourceName()}/toggle`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({
                event: buttonData.event
            })
        }).catch()
    })

    frame.appendChild(button)
    container.appendChild(frame)
}

window.addEventListener('message', (event) => {
    if (event.data.event === 'show') {
        root.style.display = 'block'
    }

    if (event.data.event === 'hide') {
        root.style.display = 'none'
    }
})

cores = {"red", "blue", "green", "teal", "black"}
indice = 1

function change_color()
    local cor_atual = cores[indice]
    set_bg(cor_atual) -- Chama a função Dart que você registrou!
    
    indice = indice + 1
    if indice > #cores then
        indice = 1
    end
end

function somar(a, b)
    return a + b
end
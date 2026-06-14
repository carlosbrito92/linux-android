# Linux no Termux — versão adaptada para Galaxy Tab A9 / A9+ (4GB)

Esta é uma versão modificada do script original de [gio.yaml](https://github.com/gio-yaml/linux-android), ajustada para tablets **Samsung Galaxy Tab A9 / A9+** com chipset **MediaTek Helio G99 (GPU Mali-G57)** e 4GB de RAM.

O script original foi escrito pensando em dispositivos com GPU **Adreno (Qualcomm)**. Em tablets com GPU **Mali**, alguns pontos precisavam de ajuste para a interface gráfica renderizar corretamente. Esta versão resolve isso e remove um componente pesado que não faz sentido num cyberdeck de uso leve.

---

## O que muda nesta versão

### 1. Driver gráfico forçado para Zink (essencial em GPU Mali)

O script original instalava o `mesa-zink` mas **não exportava as variáveis de ambiente** que efetivamente ativam o Zink. Em GPUs Mali, sem isso a renderização pode cair para software (lenta, com glitches).

Esta versão adiciona ao `start-linux.sh` gerado:

```bash
export MESA_LOADER_DRIVER_OVERRIDE=zink
export GALLIUM_DRIVER=zink
```

Isso direciona o OpenGL a rodar sobre Vulkan (Zink), que é o caminho compatível com a Mali-G57 do Helio G99.

### 2. Wine / Hangover removido

O passo de instalação do `hangover-wine` e `hangover-wowbox64` (emulação de Windows x86 sobre ARM) foi **removido**. Motivos:

- É pesado e lento num tablet de 4GB.
- Não tem utilidade num cyberdeck focado em terminal, desenvolvimento leve e navegação.
- Era uma fonte comum de falha/inchaço na instalação.

Com isso, o total de passos caiu de **11 para 10**.

### 3. Logging habilitado nos passos críticos (4 e 5)

No script original, **todos** os comandos eram silenciados com `> /dev/null 2>&1`. Se algo falhasse (pacote indisponível, falta de espaço), o script seguia em frente sem avisar.

Nesta versão, os dois passos que mais costumam falhar — **instalação do desktop (passo 4)** e **instalação do driver GPU (passo 5)** — rodam mostrando a saída real, com um aviso destacado em caso de erro:

```
[!] ATENCAO: falha ao instalar '...'. Veja o erro acima.
```

Os demais passos continuam silenciosos para não poluir o terminal.

### 4. Sobre a "detecção automática de GPU" do original

Vale registrar: a detecção de GPU prometida no README original **não tem efeito na prática**. A variável `GPU_DRIVER` nunca recebe valor, então a linha condicional do driver Freedreno (Adreno) nunca executa — todos os dispositivos acabam usando `mesa-zink`. Por acaso, isso é justamente o que funciona na Mali, mas é bom saber que a "detecção" é só informativa.

---

## Requisitos (Galaxy Tab A9 / A9+)

- Android 5.0+ (o A9 vem bem acima disso)
- Termux instalado **pelo F-Droid ou GitHub** (nunca pela Play Store — a versão de lá está desatualizada e quebra)
- Termux:X11
- ~2GB livres para o ambiente base (reserve 8–15GB se for instalar muitos apps Linux; o A9 aceita microSD)
- Conexão com internet

**Desktop recomendado:** XFCE4 (opção 1). Em 4GB, evite KDE.

---

## Instalação

1. Instale o **Termux** pelo [F-Droid](https://f-droid.org/pt_BR/packages/com.termux/).

2. Abra o Termux e dê acesso ao armazenamento:
   ```bash
   termux-setup-storage
   ```

3. Ative o **Modo Desenvolvedor** no Android.

4. Em *Opções do Desenvolvedor*, desabilite **"Desativar restrições de processos filhos"** (*Disable child process restrictions*).

5. Instale o git:
   ```bash
   pkg install git
   ```

6. Clone este repositório:
   ```bash
   git clone <URL_DO_SEU_REPOSITORIO>
   cd linux-android
   ```

7. Dê permissão de execução (atenção: **x minúsculo**) e rode:
   ```bash
   chmod +x script-termux.sh
   ./script-termux.sh
   ```

8. Escolha o desktop — digite **1** para XFCE4 (ou só Enter).

9. Aguarde a instalação. Fique de olho nos passos 4 e 5: se aparecer `[!] ATENCAO`, anote o erro.

10. Volte para a home e inicie o ambiente gráfico:
    ```bash
    cd
    ./start-linux.sh
    ```

11. Instale o [Termux:X11](https://github.com/termux/termux-x11/releases/tag/nightly).

12. Abra o app **Termux:X11** — o desktop XFCE estará rodando.

Para encerrar o desktop:
```bash
./stop-linux.sh
```

---

## Observações importantes

- **`chmod +x`, não `chmod +X`** — o `x` maiúsculo é condicional e pode não dar a permissão num `.sh` recém-clonado, resultando em `Permission denied`. Use sempre minúsculo. Cuidado também com `chmod -x`, que **remove** a permissão.

- **O Android continua intacto.** Isso não é dual-boot nem substitui o sistema. O Linux roda como um app (Termux) por cima do Android. Ligou o tablet → Android normal; quer o Linux → abre o Termux e roda `./start-linux.sh`. Tudo 100% reversível: desinstalou o Termux, acabou.

- **Início automático (opcional):** dá para fazer o `start-linux.sh` rodar sozinho ao abrir o Termux colando `./start-linux.sh` no `~/.bashrc`. Recomendo deixar isso **para depois** de tudo estável — se o script tiver erro, você entra num loop ao abrir o Termux. No começo, prefira o controle manual.

---

## Créditos

Baseado no projeto original de **[gio.yaml](https://github.com/gio-yaml/linux-android)**.
Adaptações para Galaxy Tab A9 / A9+ (Helio G99 / Mali-G57 / 4GB): ajuste de driver Zink, remoção do Wine e logging de diagnóstico.

## Licença

MIT (mantida do projeto original).

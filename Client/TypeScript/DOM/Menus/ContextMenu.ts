import { ContextMenuItem } from '../exports.js';

export class ContextMenu {
    public isOpen: boolean = false;

    public readonly node: HTMLElement;
    private readonly root: HTMLUListElement;
    private readonly action: (action: string, _: any[]) => void;

    public constructor(action: (action: string, _: any[]) => void) {
        this.action = action;

        this.root = document.createElement('ul');
        this.root.setAttribute('data-display', 'hidden');

        this.node = document.createElement('div');
        this.node.id = 'context-menu';
        this.node.appendChild(this.root);

        this.node.addEventListener('click', this.onclick.bind(this));
        this.node.addEventListener('mouseover', this.onmouseover.bind(this));
        // Prevent the context menu from showing a context menu on itself
        this.node.addEventListener('contextmenu', (event) => event.preventDefault());
    }

    private onclick(event: MouseEvent): void {
        const target = event.target as HTMLElement;
        const item: HTMLLIElement | null = target.closest('li');

        if (!item || item.classList.contains('disabled') || item.classList.contains('has-submenu')) {
            return;
        }

        const action: string | null = item.getAttribute('data-action');
        const argumentText: string | null = item.getAttribute('data-action-arguments');
        const argumentList: any[] = argumentText !== null ? JSON.parse(argumentText) : [];

        this.hide();

        if (action) {
            this.action(action, argumentList);
        }
    }

    private onmouseover(event: MouseEvent): void {
        const target: HTMLElement = event.target as HTMLElement;
        const item: HTMLLIElement | null = target.closest('li');

        if (item === null) {
            return;
        }

        const parentMenu: HTMLElement | null = item.parentElement;

        // Hide sibling submenus
        if (parentMenu !== null) {
            for (const child of parentMenu.children) {
                if (child !== item) {
                    const submenu: HTMLElement | null = child.querySelector('ul');
                    if (submenu !== null) {
                        this.hideNested(submenu);
                    }
                }
            }
        }

        // Show the direct submenu of the hovered item
        const directSubmenu: HTMLElement | null = item.querySelector('ul');
        if (directSubmenu !== null) {
            directSubmenu.setAttribute('data-display', 'floating');
        }
    }

    public show(items: ContextMenuItem[], x: number, y: number): void {
        this.root.replaceChildren();

        this.render(items, this.root);
        this.position(this.root, x, y);
        this.positionSubmenusRecursively(this.root);

        this.root.setAttribute('data-display', 'floating');

        this.isOpen = true;
    }

    public hide(): void {
        this.root.setAttribute('data-display', 'hidden');
        this.isOpen = false;
    }

    private hideNested(menu: HTMLElement) {
        menu.setAttribute('data-display', 'hidden');
        const submenus = menu.querySelectorAll('ul') as NodeListOf<HTMLElement>;
        for (const submenu of submenus) {
            submenu.setAttribute('data-display', 'hidden');
        }
    }

    private render(items: ContextMenuItem[], menu: HTMLUListElement): void {
        for (const item of items) {
            const li: HTMLLIElement = document.createElement('li');

            const content: HTMLDivElement = document.createElement('div');
            content.textContent = item.label;
            li.appendChild(content);

            if (item.disabled) {
                li.classList.add('disabled');
            }

            if (item.submenu !== undefined) {
                li.classList.add('has-submenu');
                // Recursively render the submenu and append it
                const submenu: HTMLUListElement = this.renderNested(item.submenu);
                submenu.setAttribute('data-display', 'hidden');
                content.appendChild(submenu);

            } else if (item.action !== undefined) {
                li.setAttribute('data-action', item.action);
                if (item.arguments !== undefined) {
                    li.setAttribute('data-action-arguments', JSON.stringify(item.arguments));
                }
            }
            menu.appendChild(li);
        }
    }

    private renderNested(items: ContextMenuItem[]): HTMLUListElement {
        const menu: HTMLUListElement = document.createElement('ul');
        this.render(items, menu);
        return menu;
    }


    private position(menu: HTMLElement, x: number, y: number): void {
        let left: number;
        let top: number;

        const buffer: number = 10;
        const h: number = window.innerHeight - y - buffer;
        const w: number = window.innerWidth - x - buffer;

        // The small offsets help to position the menu underneath the cursor, which hides any
        // tooltips that might otherwise appear beneath the menu.

        if (menu.offsetWidth > w) {
            left = x + 5 - menu.offsetWidth;
            this.node.style.transformOrigin = 'top right';
        } else {
            left = x - 5;
            this.node.style.transformOrigin = 'top left';
        }

        if (menu.offsetHeight > h) {
            top = y + 10 - menu.offsetHeight;
            this.node.style.transformOrigin = 'bottom left';
        } else {
            top = y - 10;
             // We already set top-left or top-right, no need to override
        }

        if ((menu.offsetWidth > w) && (menu.offsetHeight > h)) {
            this.node.style.transformOrigin = 'bottom right';
        }

        this.node.style.left = `${left}px`;
        this.node.style.top = `${top}px`;
    }
    private positionSubmenusRecursively(parent: HTMLUListElement): void {
        parent.classList.remove('has-submenu-left', 'has-submenu-right');

        for (const item of parent.children) {
            const li = item as HTMLLIElement;
            const submenu = this.directSubmenu(li);

            if (submenu) {
                const parentRect = li.getBoundingClientRect();

                if (parentRect.right + submenu.offsetWidth > window.innerWidth) {
                    li.setAttribute('data-submenu', 'left');
                    parent.classList.add('has-submenu-left');
                    submenu.style.left = `-${submenu.offsetWidth}px`;
                } else {
                    li.setAttribute('data-submenu', 'right');
                    parent.classList.add('has-submenu-right');
                    submenu.style.left = `${li.offsetWidth}px`;
                }

                if (parentRect.top + submenu.offsetHeight > window.innerHeight) {
                    submenu.style.top = `${li.offsetHeight - submenu.offsetHeight}px`;
                } else {
                    submenu.style.top = '0px';
                }

                this.positionSubmenusRecursively(submenu);
            }
        }
    }

    private directSubmenu(item: HTMLLIElement): HTMLUListElement | null {
        for (const child of item.children) {
            if (child instanceof HTMLDivElement) {
                for (const grandchild of child.children) {
                    if (grandchild instanceof HTMLUListElement) {
                        return grandchild;
                    }
                }
            }
        }
        return null;
    }
}

import { ContextMenuItem } from '../exports.js';

export class ContextMenu {
    public readonly node: HTMLElement;
    public isOpen: boolean = false;

    private readonly action: (action: string, _: any[]) => void;
    private activeSubmenus: HTMLElement[] = [];

    public constructor(action: (action: string, _: any[]) => void) {
        this.action = action;

        this.node = document.createElement('div');
        this.node.setAttribute('data-display', 'hidden');

        this.node.addEventListener('click', this.onMenuClick.bind(this));
        this.node.addEventListener('mouseover', this.onMenuMouseover.bind(this));
    }

    private onMenuClick(event: MouseEvent): void {
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

    private onMenuMouseover(event: MouseEvent): void {
        const target: HTMLElement = event.target as HTMLElement;
        const item: HTMLLIElement | null = target.closest('li');

        if (item === null) {
            return;
        }

        const parentMenu: HTMLElement | null = item.parentElement;
        const currentSubmenu: HTMLElement | null = item.querySelector('.context-menu');

        // Close sibling submenus
        if (parentMenu !== null) {
            this.closeSubmenus(parentMenu, currentSubmenu);
        }

        // Open new submenu if it exists
        if (item.classList.contains('has-submenu') && !currentSubmenu) {
             const menuDataStr = item.getAttribute('data-submenu');
             if(menuDataStr) {
                const submenuData = JSON.parse(menuDataStr) as ContextMenuItem[];
                this.createAndShowSubmenu(submenuData, item);
             }
        }
    }

    private createAndShowSubmenu(menu: ContextMenuItem[], parent: HTMLElement) {
        const submenu: HTMLUListElement = this.render(menu);
        parent.appendChild(submenu);
        this.positionSubmenu(submenu, parent);
        this.activeSubmenus.push(submenu);
    }

    private positionSubmenu(submenu: HTMLElement, parentItem: HTMLElement): void {
        const parentRect = parentItem.getBoundingClientRect();
        submenu.style.left = `${parentRect.width}px`;
        submenu.style.top = `0px`;
    }

    public show(menu: ContextMenuItem[], x: number, y: number): void {
        if (menu.length === 0) {
            return;
        }

        console.log('Showing context menu at:', x, y);

        this.node.replaceChildren(); // Clear previous menu
        this.node.appendChild(this.render(menu));

        this.node.style.left = `${x}px`;
        this.node.style.top = `${y}px`;
        this.node.setAttribute('data-display', 'floating');
        this.isOpen = true;
    }

    public hide(): void {
        this.node.setAttribute('data-display', 'hidden');
        this.node.replaceChildren();
        this.isOpen = false;
        this.activeSubmenus = [];
    }

    private closeSubmenus(parentMenu: HTMLElement, exclude: Element | null): void {
        const submenus = parentMenu.querySelectorAll('.context-menu');
        submenus.forEach(submenu => {
            if (submenu !== exclude) {
                submenu.remove();
                const index = this.activeSubmenus.indexOf(submenu as HTMLElement);
                if (index > -1) {
                    this.activeSubmenus.splice(index, 1);
                }
            }
        });
    }

    private render(items: ContextMenuItem[]): HTMLUListElement {
        const menu: HTMLUListElement = document.createElement('ul');
        menu.className = 'context-menu';

        for (const item of items) {
            const li: HTMLLIElement = document.createElement('li');
            li.textContent = item.label;

            if (item.disabled) {
                li.classList.add('disabled');
            }

            if (item.submenu) {
                li.classList.add('has-submenu');
                li.setAttribute('data-submenu', JSON.stringify(item.submenu));
            } else if (item.action) {
                li.setAttribute('data-action', item.action);
                if (item.arguments) {
                    li.setAttribute('data-action-arguments', JSON.stringify(item.arguments));
                }
            }
            menu.appendChild(li);
        }

        return menu;
    }
}

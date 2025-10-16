// import { DiffableListElement } from '../../DOM/exports.js';
// import { MarketFilterLabel, ScreenType } from "../exports.js";

// export class PopFilter implements DiffableListElement<string> {
//     public readonly id: string;
//     public readonly node: HTMLLIElement;

//     private readonly link: HTMLAnchorElement;
//     private readonly icon: HTMLSpanElement;
//     private readonly name: HTMLSpanElement;

//     constructor(market: MarketFilterLabel) {
//         this.id = market.id;
//         this.node = document.createElement('li');
//         this.link = document.createElement('a');
//         this.icon = document.createElement('span');
//         this.name = document.createElement('span');

//         this.icon.textContent = market.icon;
//         this.name.textContent = market.name;

//         this.link.href = `#screen=${ScreenType.Trade}&filter=${market.id}`;
//         this.link.appendChild(this.icon);
//         this.link.appendChild(this.name);
//         this.node.appendChild(this.link);
//     }
// }
